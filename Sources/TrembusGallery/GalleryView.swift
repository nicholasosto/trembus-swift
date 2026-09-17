import SwiftUI
import TrembusCatalog
import TrembusTokens
import TrembusUI

struct GalleryView: View {
    @Bindable var model: GalleryModel

    var body: some View {
        NavigationSplitView {
            List(selection: $model.selection) {
                ForEach(CatalogEntry.Kind.allCases, id: \.self) { kind in
                    Section(kind.rawValue) {
                        ForEach(Catalog.entries(of: kind)) { entry in
                            Label(entry.name, systemImage: kind.symbolName).tag(entry.id)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 280)
        } detail: {
            if let entry = model.entry {
                EntryDetail(entry: entry)
                    .id(entry.id)  // fresh scroll position and fresh playground state per entry
            } else {
                Text("Pick something from the sidebar").foregroundStyle(.theme(.textDim))
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Theme", selection: $model.themeMode) {
                    ForEach(ThemeMode.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .help("Theme — ⌘1 to ⌘4")
            }
        }
        .trembusTheme(model.themeMode.choice)
        .preferredColorScheme(model.themeMode.scheme)
    }
}

extension CatalogEntry.Kind {
    fileprivate var symbolName: String {
        switch self {
        case .foundation: "swatchpalette"
        case .primitive: "square.on.square.dashed"
        case .component: "switch.2"
        case .example: "rectangle.3.group"
        }
    }
}

// MARK: - Detail

private struct EntryDetail: View {
    let entry: CatalogEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s7) {
                header
                if let contract = entry.contract { ContractPanel(contract: contract) }
                ForEach(entry.specimens) { specimen in
                    SpecimenPanel(specimen: specimen)
                }
            }
            .padding(Space.s7)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.theme(.surface))
        .navigationTitle(entry.name)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack(alignment: .firstTextBaseline, spacing: Space.s4) {
                Text(entry.name)
                    .font(.trembus(.xl, weight: .bold))
                    .foregroundStyle(.theme(.text))
                Badge(entry.kind.rawValue, tone: entry.kind == .component ? .accent : .neutral, variant: .outline)
            }
            Text(entry.summary)
                .font(.trembus(.md))
                .foregroundStyle(.theme(.textDim))
            if !entry.composes.isEmpty {
                Text("composes " + entry.composes.joined(separator: " · "))
                    .font(.trembus(.xs, family: .mono))
                    .foregroundStyle(.theme(.textFaint))
            }
        }
    }
}

private struct SpecimenPanel: View {
    let specimen: Specimen

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.lg.value, style: .continuous)
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack(alignment: .firstTextBaseline, spacing: Space.s3) {
                Text(specimen.name)
                    .font(.trembus(.md, weight: .semibold))
                    .foregroundStyle(.theme(.text))
                Text(specimen.note)
                    .font(.trembus(.sm))
                    .foregroundStyle(.theme(.textDim))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                specimen.content().padding(Space.s6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.theme(.bg), in: shape)
            .overlay(shape.strokeBorder(.theme(.border), lineWidth: 1))
        }
    }
}

/// The three jobs, side by side. The lead job wears the accent.
private struct ContractPanel: View {
    let contract: ComponentContract

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            HStack(alignment: .top, spacing: Space.s4) {
                ForEach(UIJob.allCases, id: \.self) { job in
                    card(job)
                }
            }
            HStack(spacing: Space.s5) {
                if let role = contract.a11y.role { fact("role", role) }
                if !contract.a11y.keyboard.isEmpty { fact("keys", contract.a11y.keyboard.joined(separator: " ")) }
                fact("focus ring", contract.a11y.focusRing ? "yes" : "n/a")
            }
            fact("tokens", contract.tokensUsed.joined(separator: " · "))
        }
    }

    private func card(_ job: UIJob) -> some View {
        let satisfaction = contract.satisfaction(for: job)
        let isLead = job == contract.leadJob
        let shape = RoundedRectangle(cornerRadius: Radius.lg.value, style: .continuous)
        return VStack(alignment: .leading, spacing: Space.s3) {
            HStack(spacing: Space.s3) {
                Image(systemName: job.symbolName)
                    .font(.trembus(.md, weight: .semibold))
                    .foregroundStyle(.theme(isLead ? .text : .textDim))
                Text(job.title)
                    .font(.trembus(.base, weight: .semibold))
                    .foregroundStyle(.theme(.text))
                Spacer(minLength: 0)
                if isLead { Badge("Lead", tone: .accent, variant: .solid).controlSize(.small) }
            }
            Text(job.question)
                .font(.trembus(.sm, family: .display))
                .italic()
                .foregroundStyle(.theme(.textFaint))
            Text(satisfaction.satisfiedBy)
                .font(.trembus(.sm))
                .foregroundStyle(.theme(.textDim))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text("→ " + satisfaction.specimen)
                .font(.trembus(.xs, weight: .medium, family: .mono))
                .foregroundStyle(.theme(.textFaint))
        }
        .padding(Space.s5)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(.theme(.surfaceRaised), in: shape)
        .overlay(
            shape.strokeBorder(isLead ? AnyShapeStyle(.tone(.accent)) : AnyShapeStyle(.theme(.border)), lineWidth: 1))
    }

    private func fact(_ name: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s2) {
            Text(name.uppercased())
                .font(.trembus(.xs, weight: .semibold))
                .tracking(TypeScale.xs.tracking(.wide))
                .foregroundStyle(.theme(.textFaint))
            Text(value)
                .font(.trembus(.xs, family: .mono))
                .foregroundStyle(.theme(.textDim))
        }
    }
}
