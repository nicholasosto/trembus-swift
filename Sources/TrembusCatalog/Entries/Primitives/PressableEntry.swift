import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let pressable = CatalogEntry(
        name: "Pressable",
        kind: .primitive,
        summary: "The press primitive: a real button that hands your label its live InteractionState.",
        specimens: [
            Specimen("Default", note: "Pressable(action:) { state in … } — build custom controls on this") {
                VStack(spacing: Space.s2) {
                    PressableRow(symbol: "tray", title: "Inbox", count: 12)
                    PressableRow(symbol: "paperplane", title: "Sent", count: 0)
                    PressableRow(symbol: "archivebox", title: "Archive", count: 3)
                }
                .frame(width: 240)
            },
            Specimen("States", note: "frozen with .interactionOverride(_:)") {
                StateRow {
                    PressableRow(symbol: "tray", title: "Inbox", count: 12).frame(width: 150)
                }
            },
        ])
}

/// A sidebar-style row, drawn entirely from the state `Pressable` hands it.
private struct PressableRow: View {
    let symbol: String
    let title: String
    let count: Int

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous)
        Pressable(action: {}) { state in
            HStack(spacing: Space.s3) {
                Image(systemName: symbol).frame(width: 18)
                Text(title)
                Spacer(minLength: 0)
                if count > 0 {
                    Text("\(count)")
                        .font(.trembus(.xs, family: .mono))
                        .foregroundStyle(.theme(.textDim))
                }
            }
            .font(.trembus(.base, weight: state.isPressed ? .semibold : .regular))
            .foregroundStyle(.theme(.text))
            .padding(.horizontal, Space.s4)
            .frame(height: 30)
            .background(.theme(state.isPressed ? .surfaceSunken : .surfaceHover).opacity(fill(state)), in: shape)
            .contentShape(shape)
            .focusRing(state.isFocused, in: shape)
            .opacity(state.isEnabled ? 1 : 0.55)
            .motion(Motion.calm(.fast), value: state)
        }
    }

    private func fill(_ state: InteractionState) -> Double {
        state.phase == .hover || state.phase == .pressed ? 1 : 0
    }
}

struct PressableEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.pressable) }
}
