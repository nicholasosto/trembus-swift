import SwiftUI
import TrembusTokens

/// What a field currently has to say about its own validity. Plain logic, kept apart from the
/// view so it can be tested directly.
nonisolated struct FieldStatus: Sendable, Equatable {
    /// The error to show, or `nil`. Blank strings count as "no error" — callers often bind
    /// this to a validator that returns `""` when all is well, and an empty red line helps no one.
    let error: String?

    init(error: String?) {
        let trimmed = error?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.error = trimmed.isEmpty ? nil : trimmed
    }

    var isInvalid: Bool { error != nil }

    enum Edge: Equatable {
        case rest, focused, invalid
    }

    /// Invalid outranks focused: a field you are typing in is still wrong until it isn't.
    func edge(isFocused: Bool) -> Edge {
        if isInvalid { return .invalid }
        return isFocused ? .focused : .rest
    }

    /// What assistive tech hears after the label: the placeholder (while the field is empty —
    /// it is drawn by hand, so VoiceOver would otherwise never hear it), the helper text, the error.
    func accessibilityHint(description: String?, placeholder: String? = nil) -> String {
        let parts = [placeholder, description, error]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // One stop between parts — never two. Helper text usually brings its own.
        return parts.enumerated().map { index, part in
            let endsItself = part.last.map { ".!?…。".contains($0) } ?? false
            return index < parts.count - 1 && !endsItself ? part + "." : part
        }
        .joined(separator: " ")
    }
}

/// What a field says OUT LOUD. Plain string logic, kept apart from the views so it can be tested.
nonisolated enum FieldText {
    /// The field's name without decoration. A blank label falls back to the prompt, so a field is
    /// never nameless to assistive tech.
    static func name(label: String, prompt: String) -> String {
        let label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? prompt.trimmingCharacters(in: .whitespacesAndNewlines) : label
    }

    /// The name VoiceOver hears. A required field says so: the visible asterisk is decoration and is
    /// hidden from assistive tech, so without this "required" would be a sighted-only fact.
    static func accessibleName(label: String, prompt: String, isRequired: Bool) -> String {
        let base = name(label: label, prompt: prompt)
        return isRequired && !base.isEmpty ? "\(base), required" : base
    }

    /// Whether speaking the placeholder adds anything to the name. "Filter…" after "Filter" does not.
    static func placeholderAddsInformation(_ prompt: String, toName name: String) -> Bool {
        let prompt = normalized(prompt)
        return !prompt.isEmpty && prompt != normalized(name)
    }

    private static func normalized(_ string: String) -> String {
        string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }
}

/// Shared chrome for a labeled control — label, helper text, the control, a live error.
/// The single source of truth for that layout (the web's `FieldShell`): Input uses it today,
/// Textarea and Select should use it when they arrive.
///
///     label *            ← `.labelsHidden()` hides this row; the control keeps its accessible name
///     helper text
///     ┌──────────────┐
///     │ the control  │
///     └──────────────┘
///     error message
struct FieldShell<Control: View>: View {
    let label: String
    var description: String?
    var status: FieldStatus
    var isRequired = false
    /// Clicking the label should focus the control, as a `<label for>` does on the web.
    var onLabelTap: () -> Void = {}
    @ViewBuilder let control: Control

    @Environment(\.labelsVisibility) private var labelsVisibility
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.interactionOverride) private var override
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            if labelsVisibility != .hidden, !label.isEmpty {
                // One Text, so the asterisk can never wrap onto a line of its own.
                (Text(label).foregroundStyle(.theme(.text))
                    + Text(isRequired ? " *" : "").foregroundStyle(.tone(.danger, .text)))
                    .font(.trembus(.sm, weight: .medium))
                    // A frozen state (for stills) must dim the label exactly as the real one does.
                    .opacity(override?.isEnabled ?? isEnabled ? 1 : 0.6)
                    .onTapGesture(perform: onLabelTap)
                    .accessibilityHidden(true)  // the control carries the accessible name
            }
            if let description = description?.trimmingCharacters(in: .whitespacesAndNewlines), !description.isEmpty {
                Text(description)
                    .font(.trembus(.sm))
                    .foregroundStyle(.theme(.textDim))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)  // read as the control's hint instead
            }
            control
            if let error = status.error {
                HStack(alignment: .firstTextBaseline, spacing: Space.s2) {
                    // Tone is never the only signal: the words say it, and a glyph joins them
                    // when color can't be relied on.
                    if differentiateWithoutColor {
                        Image(systemName: "exclamationmark.circle.fill").accessibilityHidden(true)
                    }
                    Text(error).fixedSize(horizontal: false, vertical: true)
                }
                .font(.trembus(.sm))
                .foregroundStyle(.tone(.danger, .text))
                .transition(.opacity)
                .accessibilityHidden(true)  // announced when it appears, and part of the hint
            }
        }
        .motion(Motion.calm(.fast), value: status)
        // The web marks the error `role="alert"`. Same effect: say it the moment it appears.
        .onChange(of: status.error) { _, newError in
            if let newError { AccessibilityNotification.Announcement(newError).post() }
        }
    }
}
