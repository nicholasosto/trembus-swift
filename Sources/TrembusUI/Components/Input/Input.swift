import AppKit
import SwiftUI
import TrembusTokens

/// A labeled, single-line text field. NOT for multi-line text (that is a Textarea) and not for
/// choosing from a list (a Select).
///
///     Input("Email", text: $email, prompt: "you@example.com")
///     Input("Email", text: $email, description: "We never share it.", error: emailError, isRequired: true)
///     Input("Search", text: $query, prompt: "Search") { Image(systemName: "magnifyingglass") }
///         .labelsHidden()                 // no visible label; VoiceOver still says "Search"
///         .controlSize(.small)
///     Input("Password", text: $password, isSecure: true)
///     Input("Weight", text: $weight, trailing: { Text("kg") })
///
/// A VIEW, not a `TextFieldStyle`: SwiftUI has no public way to write one (the protocol's only
/// requirement is underscored), so this wraps a plain `TextField` in Trembus chrome instead.
/// You still get the real thing — `.onSubmit`, `.textContentType`, `.autocorrectionDisabled`
/// and friends all reach the field inside.
///
/// What it works out for itself:
/// - **error** — a non-blank `error` turns the edge danger-toned, shows the message, and announces it
/// - **size** — follows `.controlSize(_:)`, at the same heights as a Trembus button so they line up
/// - **the whole box is the target** — clicking the label, the padding, or an icon focuses the field
public struct Input<Leading: View, Trailing: View>: View {
    private let label: String
    @Binding private var text: String
    private let prompt: String
    private let description: String?
    private let status: FieldStatus
    private let isRequired: Bool
    private let isSecure: Bool
    private let leading: Leading
    private let trailing: Trailing

    @FocusState private var isFocused: Bool
    /// An input method is composing (marked text). It lives in the field editor, NOT in `text`.
    @State private var isComposing = false
    /// Set when WE hand focus to the field — a click on the box's chrome, or the secure ⇄ plain swap.
    /// AppKit answers a programmatic focus with SELECT-ALL, so the next keystroke would replace
    /// everything. The first selection change after our request is collapsed to the end instead.
    /// Tab never sets this: select-all is exactly what a keyboard user expects.
    @State private var wantsCaretAtEnd = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.multilineTextAlignment) private var textAlignment
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.theme) private var theme
    @Environment(\.controlSize) private var controlSize

    /// - Parameters:
    ///   - label: the accessible name, and the visible label unless `.labelsHidden()`.
    ///   - prompt: placeholder shown while empty.
    ///   - description: helper text between the label and the field.
    ///   - error: a validation message. `nil` or blank means valid.
    ///   - leading: an adornment inside the frame, before the text (an icon, a prefix).
    ///   - trailing: an adornment inside the frame, after the text (a unit, a status icon).
    ///
    /// One initializer, with both adornments defaulted — NOT a family of overloads. A separate
    /// trailing-only overload would make `Input(…) { Image(…) }` ambiguous; defaults keep that single
    /// trailing closure bound to `leading`, and let `trailing:` be given on its own.
    public init(
        _ label: String, text: Binding<String>, prompt: String = "", description: String? = nil,
        error: String? = nil, isRequired: Bool = false, isSecure: Bool = false,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.label = label
        self._text = text
        self.prompt = prompt
        self.description = description
        self.status = FieldStatus(error: error)
        self.isRequired = isRequired
        self.isSecure = isSecure
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        FieldShell(
            label: label, description: description, status: status, isRequired: isRequired,
            onLabelTap: focusFromChrome
        ) {
            InteractionReader(focus: isFocused) { state in
                frame(state)
            }
        }
    }

    private func frame(_ state: InteractionState) -> some View {
        let metrics = ControlMetrics.input(.init(controlSize))
        let shape = RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous)

        return HStack(spacing: Space.s3) {
            leading.foregroundStyle(.theme(.textDim))
            field
            trailing.foregroundStyle(.theme(.textDim))
        }
        .font(.trembus(metrics.type))
        .padding(.horizontal, metrics.paddingX)
        .frame(height: metrics.height)
        .fieldBox(state, status: status, in: shape)
        // The whole box is the click target, and says so with a text cursor.
        .onTapGesture(perform: focusFromChrome)
        .pointerStyle(state.isEnabled ? .horizontalText : .default)
    }

    private var field: some View {
        ZStack(alignment: placeholderAlignment) {
            // macOS's native field ignores ANY styling on `prompt:` (even pure red) and paints a
            // dark gray of its own — dark enough that an empty field looks pre-filled. So the
            // placeholder is drawn here, in `textFaint`. A plain field has no text inset (measured:
            // an overlay at offset 0 hides the native text exactly), so no nudging is needed.
            if text.isEmpty, !prompt.isEmpty, !isComposing {
                Text(prompt)
                    .foregroundStyle(.theme(.textFaint))
                    .lineLimit(1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)  // spoken as part of the hint instead
            }
            // The native field gets an EMPTY title: with no prompt, macOS falls back to painting the
            // title as a placeholder — right on top of ours. The accessible name is set explicitly.
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .textFieldStyle(.plain)
            .labelsHidden()
            // FieldShell draws the visible label; this names the field — and says "required" out loud.
            .accessibilityLabel(FieldText.accessibleName(label: label, prompt: prompt, isRequired: isRequired))
            .foregroundStyle(.theme(.text))
            .tint(theme.color.accent.color)  // caret and selection
            .focused($isFocused)
            .accessibilityHint(
                status.accessibilityHint(
                    description: description, placeholder: spokenPlaceholder)
            )
            // SwiftUI holds `text` back until a composition commits, so ask the field editor instead.
            .onReceive(NotificationCenter.default.publisher(for: NSText.didChangeNotification)) { note in
                guard isFocused, let editor = note.object as? NSTextView else { return }
                isComposing = editor.hasMarkedText()
            }
            .onChange(of: isFocused) { _, focused in if !focused { isComposing = false } }
            // TextField <-> SecureField is a different native view; the swap drops focus. Hand it back.
            .onChange(of: isSecure) { _, _ in
                guard isFocused else { return }
                expectProgrammaticFocus()
                DispatchQueue.main.async { isFocused = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)) { note in
                guard wantsCaretAtEnd, let editor = note.object as? NSTextView, editor.isFieldEditor,
                    editor.string == text
                else { return }
                wantsCaretAtEnd = false
                // Next turn: AppKit is still in the middle of taking focus when this arrives.
                DispatchQueue.main.async {
                    let end = (editor.string as NSString).length
                    guard editor.string == text, editor.selectedRange().length > 0 else { return }
                    editor.setSelectedRange(NSRange(location: end, length: 0))
                }
            }
        }
    }

    /// A click on the label, the padding, or an adornment. Focuses the field with the caret at the END.
    /// (A click on the native field itself never comes here — AppKit places the caret where you clicked.)
    private func focusFromChrome() {
        guard isEnabled, !isFocused else { return }
        expectProgrammaticFocus()
        isFocused = true
    }

    private func expectProgrammaticFocus() {
        wantsCaretAtEnd = true
        // Never let the request outlive its moment: a stale flag would hijack a later Tab's select-all.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { wantsCaretAtEnd = false }
    }

    /// The placeholder is drawn by hand, so VoiceOver only hears it if it is put in the hint — while
    /// the field is empty, and only when it says something the name doesn't ("Filter…" after "Filter").
    private var spokenPlaceholder: String? {
        let name = FieldText.name(label: label, prompt: prompt)
        return text.isEmpty && FieldText.placeholderAddsInformation(prompt, toName: name) ? prompt : nil
    }

    /// Where the NATIVE field will put its text, so the hand-drawn placeholder sits in the same place.
    private var placeholderAlignment: Alignment {
        Alignment(
            horizontal: FieldText.placeholderAlignment(
                textAlignment, layoutDirection: layoutDirection,
                appIsRTL: NSApp?.userInterfaceLayoutDirection == .rightToLeft),
            vertical: .center)
    }
}
