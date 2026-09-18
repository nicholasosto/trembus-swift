import AppKit
import SwiftUI
import TrembusTokens

/// One thing a `Select` offers: a value, and the words that stand for it.
nonisolated public struct SelectOption<Value: Hashable>: Identifiable {
    public let title: String
    public let value: Value
    /// `false` keeps the option in the list, dimmed — it can be read but not chosen.
    public let isEnabled: Bool

    public var id: Value { value }

    public init(_ title: String, value: Value, isEnabled: Bool = true) {
        self.title = title
        self.value = value
        self.isEnabled = isEnabled
    }
}

/// A labeled field for choosing ONE option from a closed list. NOT for free text (that is an Input),
/// not for on / off (a Switch), and not for running commands (a menu).
///
///     Select("Role", selection: $role, options: roles, prompt: "Choose a role")
///     Select("Role", selection: $role, options: roles, description: "Decides what they can change.",
///         error: roleError, isRequired: true)
///     Select("Theme", selection: $theme, options: themes)   // `theme` is never nil, so there is no prompt
///         .labelsHidden()
///         .controlSize(.small)
///
///     let roles = Role.allCases.map { SelectOption($0.title, value: $0) }
///
/// A VIEW, not a `PickerStyle`: SwiftUI has no public way to write one, and a native `Picker` paints
/// its own chrome and its own text color, which no theme can reach. So the closed field is Trembus —
/// the same box as an Input — and the open list is the Mac's own pop-up menu: arrow keys, type-to-find,
/// scrolling past the screen edge and VoiceOver all come with it, as they do with the web's `<select>`.
///
/// What it works out for itself:
/// - **error** — a non-blank `error` turns the edge danger-toned, shows the message, and announces it
/// - **size** — follows `.controlSize(_:)`, at the same heights as an Input so a form lines up
/// - **nothing chosen** — a `nil` selection, or a value the list does not hold, shows the prompt
public struct Select<Value: Hashable>: View {
    private let label: String
    @Binding private var selection: Value?
    private let options: [SelectOption<Value>]
    private let prompt: String
    private let description: String?
    private let status: FieldStatus
    private let isRequired: Bool

    /// How the button (Space, the arrow keys, VoiceOver) reaches the menu the mouse opens.
    @State private var menu = SelectMenuHandle()
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    /// - Parameters:
    ///   - label: the accessible name, and the visible label unless `.labelsHidden()`.
    ///   - selection: the chosen value. `nil` means nothing is chosen yet.
    ///   - prompt: shown while nothing is chosen. It is never in the list, so it can never be chosen.
    ///   - description: helper text between the label and the field.
    ///   - error: a validation message. `nil` or blank means valid.
    public init(
        _ label: String, selection: Binding<Value?>, options: [SelectOption<Value>], prompt: String = "",
        description: String? = nil, error: String? = nil, isRequired: Bool = false
    ) {
        self.label = label
        self._selection = selection
        self.options = options
        self.prompt = prompt
        self.description = description
        self.status = FieldStatus(error: error)
        self.isRequired = isRequired
    }

    /// For a value that is never empty. There is no "nothing chosen", so there is no prompt.
    public init(
        _ label: String, selection: Binding<Value>, options: [SelectOption<Value>], description: String? = nil,
        error: String? = nil, isRequired: Bool = false
    ) {
        self.init(
            label, selection: selection.refusingNil, options: options, description: description, error: error,
            isRequired: isRequired)
    }

    public var body: some View {
        FieldShell(label: label, description: description, status: status, isRequired: isRequired) {
            Pressable(action: menu.open) { state in
                box(state)
            }
            // A Mac pop-up opens on the arrow keys as well as on Space.
            .onKeyPress(keys: [.upArrow, .downArrow]) { _ in
                menu.open()
                return .handled
            }
            // FieldShell draws the visible label; this names the field — and says "required" out loud.
            .accessibilityLabel(FieldText.accessibleName(label: label, prompt: prompt, isRequired: isRequired))
            .accessibilityValue(shownText)
            .accessibilityHint(status.accessibilityHint(description: description))
            .overlay {
                SelectMenuAnchor(
                    handle: menu, items: options.map { .init(title: $0.title, isEnabled: $0.isEnabled) },
                    chosenIndex: chosenIndex, isEnabled: isEnabled, onChoose: choose
                )
                .accessibilityHidden(true)  // the button above is the one element
            }
        }
    }

    private func box(_ state: InteractionState) -> some View {
        let metrics = ControlMetrics.select(.init(controlSize))
        let shape = RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous)

        return HStack(spacing: Space.s3) {
            Text(shownText)
                .foregroundStyle(.theme(chosenIndex == nil ? .textFaint : .text))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            // Up AND down: the list pops up over the field with the chosen option under the pointer —
            // it does not drop down from it. The web's mark is a single down chevron.
            Image(systemName: "chevron.up.chevron.down")
                .font(.trembus(metrics.glyph, weight: .medium))
                .foregroundStyle(.theme(.textDim))
                .accessibilityHidden(true)
        }
        .font(.trembus(metrics.type))
        .padding(.horizontal, metrics.paddingX)
        .frame(height: metrics.height)
        .fieldBox(state, status: status, in: shape)
    }

    // MARK: - Logic (internal, so it can be tested)

    /// Where the selection sits in the list. `nil` when nothing is chosen — or when the value is not
    /// one the list holds, which reads the same way: the field must never show words it did not offer.
    var chosenIndex: Int? {
        guard let selection else { return nil }
        return options.firstIndex { $0.value == selection }
    }

    /// The words in the closed field: the chosen option, else the prompt.
    var shownText: String {
        chosenIndex.map { options[$0].title } ?? prompt
    }

    /// The menu reports a row. Only a row that exists, and may be chosen, becomes the selection.
    func choose(_ index: Int) {
        guard options.indices.contains(index), options[index].isEnabled else { return }
        selection = options[index].value
    }
}

extension Binding where Value: Hashable {
    /// This binding seen as an optional one that ignores `nil`, so a value that is never empty can
    /// feed the same field as one that may be. (A key path, not a pair of closures: a `Binding`'s
    /// closures must be `Sendable`, and `Value` is only asked to be `Hashable`.)
    fileprivate var refusingNil: Binding<Value?> { self[dynamicMember: \.orItself] }
}

nonisolated extension Hashable {
    fileprivate var orItself: Self? {
        get { self }
        set { if let newValue { self = newValue } }
    }
}

// MARK: - The AppKit corner

/// How the SwiftUI button reaches the AppKit view, so Space, the arrow keys and VoiceOver open the
/// SAME menu the mouse does.
final class SelectMenuHandle {
    weak var view: SelectMenuView?

    func open() { view?.open() }
}

/// An invisible AppKit view laid over the box. Two jobs:
/// - it opens the menu on mouse-DOWN, as every Mac pop-up does, so press · drag · release chooses in one
///   gesture (a SwiftUI button only acts on mouse-UP);
/// - it is what the native menu is positioned against.
///
/// Not generic, and not nested in `Select`: it speaks in row numbers, so one type serves every `Value`.
private struct SelectMenuAnchor: NSViewRepresentable {
    let handle: SelectMenuHandle
    let items: [SelectMenuView.Item]
    let chosenIndex: Int?
    let isEnabled: Bool
    let onChoose: (Int) -> Void

    func makeNSView(context: Context) -> SelectMenuView { SelectMenuView() }

    func updateNSView(_ view: SelectMenuView, context: Context) {
        handle.view = view
        view.items = items
        view.chosenIndex = chosenIndex
        view.isEnabled = isEnabled
        view.onChoose = onChoose
    }
}

final class SelectMenuView: NSView {
    struct Item: Equatable {
        let title: String
        let isEnabled: Bool
    }

    var items: [Item] = []
    var chosenIndex: Int?
    var isEnabled = true
    var onChoose: (Int) -> Void = { _ in }

    /// Top-left origin, like SwiftUI — so `.zero` below is the box's top-left corner.
    override var isFlipped: Bool { true }

    override func mouseDown(with event: NSEvent) { open() }

    /// Runs the menu, and returns once it has closed.
    func open() {
        guard isEnabled, !items.isEmpty, window != nil else { return }
        let menu = makeMenu()
        // Positioned as a pop-up: the chosen row lands over the field, so a plain click-and-release
        // changes nothing. With nothing chosen, the list starts at the field's top edge.
        menu.popUp(positioning: chosenIndex.flatMap { menu.item(at: $0) }, at: .zero, in: self)
    }

    /// One row per option, in order; the chosen one is checked. Never narrower than the field.
    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false  // a row is enabled because its OPTION is, not because of a responder
        menu.minimumWidth = bounds.width
        for (index, item) in items.enumerated() {
            let row = NSMenuItem(title: item.title, action: #selector(rowChosen(_:)), keyEquivalent: "")
            row.target = self
            row.tag = index
            row.isEnabled = item.isEnabled
            row.state = index == chosenIndex ? .on : .off
            menu.addItem(row)
        }
        return menu
    }

    @objc private func rowChosen(_ sender: NSMenuItem) { onChoose(sender.tag) }
}
