import SwiftUI
import TrembusTokens
import TrembusUI

/// One specimen on its stage: the theme's page color behind it, room to breathe around it.
public struct SpecimenStage: View {
    let specimen: Specimen
    let theme: Theme

    public init(_ specimen: Specimen, theme: Theme) {
        self.specimen = specimen
        self.theme = theme
    }

    public var body: some View {
        specimen.content()
            .padding(Space.s6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.theme(.bg))
            .trembusTheme(theme)
    }
}

/// The contact sheet for one entry: every specimen, in every theme, in ONE image.
///
///     ┌ Button ─────────────────────────┐
///     │ Default                          │
///     │  light     ▢ ▢ ▢                 │
///     │  dark      ▣ ▣ ▣                 │
///     │  reliquary ▣ ▣ ▣                 │
///     │ States …                         │
///
/// Themes stack as horizontal bands (not columns) so wide specimens — a row of five
/// states — stay readable.
public struct EntrySheet: View {
    let entry: CatalogEntry
    let themes: [Theme]

    public init(_ entry: CatalogEntry, themes: [Theme] = Theme.all) {
        self.entry = entry
        self.themes = themes
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ForEach(entry.specimens) { specimen in
                specimenHeader(specimen)
                ForEach(themes) { theme in
                    band(specimen, theme)
                }
            }
        }
        .fixedSize()
        .background(.theme(.surface))
        .trembusTheme(.light)  // sheet chrome is always light; the bands carry the themes
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s4) {
            Text(entry.name).font(.trembus(.lg, weight: .bold))
            Text(entry.kind.rawValue.uppercased())
                .font(.trembus(.xs, weight: .semibold))
                .tracking(TypeScale.xs.tracking(.caps))
                .foregroundStyle(.theme(.textDim))
            if let contract = entry.contract {
                Text("leads with " + contract.leadJob.title)
                    .font(.trembus(.xs))
                    .foregroundStyle(.theme(.textDim))
            }
        }
        .foregroundStyle(.theme(.text))
        .padding(.horizontal, Space.s5)
        .padding(.vertical, Space.s4)
    }

    private func specimenHeader(_ specimen: Specimen) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s3) {
            Text(specimen.name).font(.trembus(.sm, weight: .semibold))
            Text(specimen.note).font(.trembus(.xs)).foregroundStyle(.theme(.textDim))
        }
        .foregroundStyle(.theme(.text))
        .padding(.horizontal, Space.s5)
        .padding(.vertical, Space.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.theme(.surfaceSunken))
    }

    private func band(_ specimen: Specimen, _ theme: Theme) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(theme.name)
                .font(.trembus(.xs, family: .mono))
                .foregroundStyle(.theme(.textFaint))
                .frame(width: 72, alignment: .leading)
                .padding(.leading, Space.s5)
                .padding(.top, Space.s6)
            SpecimenStage(specimen, theme: theme)
        }
        .background(theme.color.bg.color)
        .trembusTheme(theme)
    }
}
