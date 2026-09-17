import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let colors = CatalogEntry(
        name: "Colors",
        kind: .foundation,
        summary: "Chrome colors and the six-tone ontology. Components say .theme(.surface) — never a hex.",
        specimens: [
            Specimen("Chrome", note: "ColorToken — page, surfaces, edges, text, accent") {
                ChromeSwatches()
            },
            Specimen("Tones", note: "Tone × ToneRole — base · bg · fg · text") {
                ToneMatrix()
            },
        ])
}

private struct ChromeSwatches: View {
    private static let groups: [(String, [ColorToken])] = [
        ("surface", [.bg, .surface, .surfaceRaised, .surfaceSunken, .surfaceHover, .overlay]),
        ("border", [.borderSoft, .border, .borderStrong]),
        ("text", [.text, .textDim, .textFaint]),
        ("accent", [.accent, .accentHover, .accentActive, .accentFg, .focusRing]),
    ]

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s5) {
            ForEach(Self.groups, id: \.0) { title, tokens in
                MatrixRow(title) {
                    HStack(alignment: .top, spacing: Space.s4) {
                        ForEach(tokens, id: \.self) { token in swatch(token, isText: title == "text") }
                    }
                }
            }
        }
    }

    private func swatch(_ token: ColorToken, isText: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous)
        return VStack(alignment: .leading, spacing: Space.s2) {
            ZStack {
                if isText {
                    shape.fill(.theme(.surface))
                    Text("Aa").font(.trembus(.lg, weight: .semibold)).foregroundStyle(.theme(token))
                } else {
                    shape.fill(.theme(token))
                }
            }
            .frame(width: 92, height: 44)
            .overlay(shape.strokeBorder(.theme(.border), lineWidth: 1))
            Text(token.rawValue).font(.trembus(.xs, weight: .medium)).foregroundStyle(.theme(.text))
            Text(theme.color[token].hex)
                .font(.trembus(.xs, family: .mono)).foregroundStyle(.theme(.textFaint))
        }
        .frame(width: 92, alignment: .leading)
    }
}

private struct ToneMatrix: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            ForEach(Tone.allCases, id: \.self) { tone in
                MatrixRow(tone.rawValue) {
                    HStack(spacing: Space.s4) {
                        chip("solid", fill: .tone(tone), ink: .tone(tone, .fg))
                        chip("soft", fill: .tone(tone, .bg), ink: .tone(tone, .text))
                        Text("as text")
                            .font(.trembus(.base, weight: .medium))
                            .foregroundStyle(.tone(tone, .text))
                            .frame(width: 64, alignment: .leading)
                        Text(theme.tone(tone).base.hex)
                            .font(.trembus(.xs, family: .mono))
                            .foregroundStyle(.theme(.textFaint))
                    }
                }
            }
        }
    }

    private func chip(_ label: String, fill: ToneColor, ink: ToneColor) -> some View {
        Text(label)
            .font(.trembus(.sm, weight: .semibold))
            .foregroundStyle(ink)
            .frame(width: 72, height: 28)
            .background(fill, in: RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous))
    }
}

struct ColorsEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.colors) }
}
