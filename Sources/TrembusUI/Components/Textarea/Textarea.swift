import AppKit
import SwiftUI
import TrembusTokens

/// A labeled field for plain text that runs over several lines. NOT for a single line (that is an
/// Input — there Return submits; here Return starts a new line) and not for styled text.
///
///     Textarea("Notes", text: $notes, prompt: "Anything the next person should know")
///     Textarea("Bio", text: $bio, description: "Shown on your profile.", error: bioError, isRequired: true)
///     Textarea("Commit message", text: $message, lines: 2...6)
///         .labelsHidden()                 // no visible label; VoiceOver still says "Commit message"
///         .controlSize(.small)
///
/// A VIEW around SwiftUI's `TextEditor`, for the same reason Input is one: there is no public style
/// protocol to write. You still get the real thing — selection, undo, spelling, dictation, services.
///
/// What it works out for itself:
/// - **height** — `lines.lowerBound` tall when empty, grows with the text up to `lines.upperBound`, then scrolls
/// - **Tab** — moves focus on, as it does in every other field. A native text view would type a tab instead
/// - **error** — a non-blank `error` turns the edge danger-toned, shows the message, and announces it
/// - **the whole box is the target** — clicking the label or the padding focuses the field
public struct Textarea: View {
    private let label: String
    @Binding private var text: String
    private let prompt: String
    private let description: String?
    private let status: FieldStatus
    private let isRequired: Bool
    private let lines: ClosedRange<Int>

    @FocusState private var isFocused: Bool
    /// An input method is composing (marked text). It lives in the text view, NOT in `text`.
    @State private var isComposing = false
    /// What the text view holds WHILE composing. `text` is held back until the composition commits, so
    /// without this the box would not grow for a long composition, then jump when it lands.
    @State private var composingText: String?
    /// Width the native scroll view keeps for a CLASSIC scroll bar (shown whenever a mouse is plugged in, or
    /// by choice in System Settings). It is reserved even when there is nothing to scroll, so the native text
    /// wraps that much narrower — and the invisible sizer must too, or the box comes out lines too short.
    @State private var scrollBarGutter = Textarea.scrollBarGutter()
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
    ///   - lines: how tall the field may be, in lines of text — the fewest (even when empty) and the most
    ///     (after which it scrolls). `4...4` is a fixed height. Never fewer than 2: one line is an Input.
    public init(
        _ label: String, text: Binding<String>, prompt: String = "", description: String? = nil,
        error: String? = nil, isRequired: Bool = false, lines: ClosedRange<Int> = 4...10
    ) {
        self.label = label
        self._text = text
        self.prompt = prompt
        self.description = description
        self.status = FieldStatus(error: error)
        self.isRequired = isRequired
        self.lines = Self.usable(lines)
    }

    public var body: some View {
        FieldShell(
            label: label, description: description, status: status, isRequired: isRequired,
            onLabelTap: focusFromChrome
        ) {
            InteractionReader(focus: isFocused) { state in
                box(state)
            }
        }
    }

    private func box(_ state: InteractionState) -> some View {
        let metrics = ControlMetrics.textarea(.init(controlSize))
        let shape = RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous)

        // A `TextEditor` has no height of its own — it fills whatever it is given. So invisible text
        // decides the height, and the editor is laid over it.
        return
            sizer
            .overlay(alignment: placeholderAlignment) { placeholder }
            .overlay { editor }
            .font(.trembus(metrics.type))
            // The native text view brings `nativeTextInset` of its own; together they make `paddingX`,
            // so the text starts exactly under the text of an Input above it.
            .padding(.horizontal, metrics.paddingX - Self.nativeTextInset)
            .padding(.vertical, metrics.paddingY)
            .fieldBox(state, status: status, in: shape)
            // The whole box is the click target, and says so with a text cursor.
            .onTapGesture(perform: focusFromChrome)
            .pointerStyle(state.isEnabled ? .horizontalText : .default)
    }

    /// Never seen. Two invisible texts, and the taller one wins: blank lines hold the minimum height
    /// open; a copy of the real text, wrapped exactly as the editor wraps it, pushes it up to the maximum.
    private var sizer: some View {
        ZStack(alignment: .topLeading) {
            Text(Self.blankLines(lines.lowerBound))
            Text(Self.sizingText(composingText ?? text)).lineLimit(lines.upperBound)
        }
        .padding(.horizontal, Self.nativeTextInset)
        .padding(scrollBarEdge, scrollBarGutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hidden()
        .accessibilityHidden(true)
    }

    @ViewBuilder private var placeholder: some View {
        // Drawn by hand, like Input's — `TextEditor` has no prompt at all.
        if text.isEmpty, !prompt.isEmpty, !isComposing {
            Text(prompt)
                .foregroundStyle(.theme(.textFaint))
                .padding(.horizontal, Self.nativeTextInset)
                .padding(scrollBarEdge, scrollBarGutter)
                .allowsHitTesting(false)
                .accessibilityHidden(true)  // spoken as part of the hint instead
        }
    }

    private var editor: some View {
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)  // the box draws the fill
            .foregroundStyle(theme.color.text.color)
            .tint(theme.color.accent.color)  // caret and selection
            .focused($isFocused)
            // FieldShell draws the visible label; this names the field — and says "required" out loud.
            .accessibilityLabel(FieldText.accessibleName(label: label, prompt: prompt, isRequired: isRequired))
            .accessibilityHint(status.accessibilityHint(description: description, placeholder: spokenPlaceholder))
            // A native text view TYPES a tab. In a form, Tab means "next field" — everywhere, including here.
            // (Shift-Tab arrives as a different character — "backtab" — not as Tab with a modifier.)
            .onKeyPress(keys: [.tab, Self.backtab]) { press in
                guard !isComposing else { return .ignored }  // an input method may be using it
                let backwards = press.key == Self.backtab || press.modifiers.contains(.shift)
                // The window this very key press was sent to — known now, gone by the next turn.
                let eventWindow = NSApp?.currentEvent?.window
                // Next turn: the key event is still being handled when this runs.
                DispatchQueue.main.async {
                    // Failing that (an event delivered by hand, as the tests do): the window whose focus is
                    // in a full text view. Asked of the windows, not of `NSApp.keyWindow` — that is nil
                    // whenever the app is not active.
                    let window =
                        eventWindow
                        ?? NSApp?.windows.first { window in
                            guard window.isKeyWindow, let view = window.firstResponder as? NSTextView else {
                                return false
                            }
                            return !view.isFieldEditor
                        }
                    guard let window else { return }
                    if backwards { window.selectPreviousKeyView(nil) } else { window.selectNextKeyView(nil) }
                }
                return .handled
            }
            // SwiftUI holds `text` back until a composition commits, so ask the text view instead. Unlike a
            // field editor, a full text view posts NO `didChange` for marked text (measured) — but its
            // selection moves on every composing keystroke, and again when the composition commits.
            .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)) {
                noteComposition(in: $0.object)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSText.didChangeNotification)) {
                noteComposition(in: $0.object)
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    isComposing = false
                    composingText = nil
                }
            }
            // Plugging a mouse in flips every scroll view to classic bars, live.
            .onReceive(
                NotificationCenter.default.publisher(for: NSScroller.preferredScrollerStyleDidChangeNotification)
            ) {
                _ in scrollBarGutter = Self.scrollBarGutter()
            }
    }

    /// Where the NATIVE text view will put its first line, so the hand-drawn placeholder sits there too.
    private var placeholderAlignment: Alignment {
        Alignment(
            horizontal: FieldText.placeholderAlignment(
                textAlignment, layoutDirection: layoutDirection,
                appIsRTL: NSApp?.userInterfaceLayoutDirection == .rightToLeft),
            vertical: .top)
    }

    private func noteComposition(in object: Any?) {
        // Only OUR text view: the one holding focus in its window while this field is focused.
        guard isFocused, let view = object as? NSTextView, let window = view.window, window.isKeyWindow,
            window.firstResponder === view
        else { return }
        isComposing = view.hasMarkedText()
        composingText = isComposing ? view.string : nil
    }

    /// A click on the label or the padding. (A click on the text itself never comes here — AppKit
    /// places the caret where you clicked.) Unlike a text FIELD, a text view keeps its caret when it
    /// is handed focus, so there is no select-all to undo.
    private func focusFromChrome() {
        guard isEnabled, !isFocused else { return }
        isFocused = true
    }

    /// The placeholder is drawn by hand, so VoiceOver only hears it if it is put in the hint — while
    /// the field is empty, and only when it says something the name doesn't.
    private var spokenPlaceholder: String? {
        let name = FieldText.name(label: label, prompt: prompt)
        return text.isEmpty && FieldText.placeholderAddsInformation(prompt, toName: name) ? prompt : nil
    }

    // MARK: - Plain logic, kept apart so it can be tested

    /// What a native text view adds on each side of its text (`lineFragmentPadding`). Measured, and
    /// held by `theNativeTextViewInsetsAreWhatTheLayoutAssumes` — not a design value, so not a token.
    nonisolated static let nativeTextInset: CGFloat = 5

    /// What AppKit sends for Shift-Tab (`NSBackTabCharacter`).
    nonisolated static let backtab = KeyEquivalent("\u{19}")

    /// The side the native scroll bar sits on. It follows the APP's direction, like the native text does.
    private var scrollBarEdge: Edge.Set {
        let appIsRTL = NSApp?.userInterfaceLayoutDirection == .rightToLeft
        return appIsRTL == (layoutDirection == .rightToLeft) ? .trailing : .leading
    }

    /// 0 with overlay scroll bars (they float over the text); the bar's width with classic ones.
    static func scrollBarGutter(for style: NSScroller.Style = NSScroller.preferredScrollerStyle) -> CGFloat {
        style == .legacy ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy) : 0
    }

    /// At least two lines (one line of text is an Input — the Form says so), and at most 100 to start with.
    nonisolated static func usable(_ lines: ClosedRange<Int>) -> ClosedRange<Int> {
        // The fewest lines are held open by that many blank lines of real text, so it has a ceiling too.
        let fewest = min(max(2, lines.lowerBound), 100)
        return fewest...max(fewest, lines.upperBound)
    }

    /// `count` lines of nothing. Each line holds a space: a line that is truly empty may not be measured.
    nonisolated static func blankLines(_ count: Int) -> String {
        Array(repeating: " ", count: max(1, count)).joined(separator: "\n")
    }

    /// The text, as the sizer should measure it. A trailing newline is a real, empty last line in the
    /// editor (the caret sits on it), but plain text drops it — the closing space keeps it counted.
    nonisolated static func sizingText(_ text: String) -> String {
        text + " "
    }
}
