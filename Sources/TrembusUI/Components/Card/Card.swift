import SwiftUI
import TrembusTokens

/// A raised surface that groups related content into one unit: header, body, footer.
/// NOT the base for other containers — Dialog, Menu and friends build on `Surface`, as Card does.
///
///     Card("Storage") { Meter(value: 0.4) }
///     Card { bodyContent } header: { Text("Storage") } footer: { Button("Manage") {} }
///
///     Button { open() } label: { Card("Storage") { … } }.buttonStyle(.trembusCard)   // a pressable card
///
/// Slots, not free-form children: the hairlines and padding between sections can't be got wrong.
/// An omitted slot — or one whose closure produced nothing — leaves no gap and no hairline. Footer content sits trailing, like the web's.
public struct Card<Header: View, Content: View, Footer: View>: View {
    private let header: Header
    private let content: Content
    private let footer: Footer
    @Environment(\.cardInteraction) private var interaction

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.init(header: header(), content: content(), footer: footer())
    }

    private init(header: Header, content: Content, footer: Footer) {
        self.header = header
        self.content = content
        self.footer = footer
    }

    public var body: some View {
        Surface(.raised, radius: .lg, padding: Space.s0, clipsContent: true, emphasis: interaction.cardEmphasis) {
            VStack(alignment: .leading, spacing: Space.s0) {
                // `Group(subviews:)` looks at what a slot PRODUCED, not at which init was called: a slot
                // that came out empty (`header: { if let title { … } }`) draws no band and no hairline,
                // and a slot with several views is stacked into ONE section, not padded view by view.
                Group(subviews: header) { views in
                    if !views.isEmpty {
                        VStack(alignment: .leading, spacing: Space.s0) { views }
                            .font(.trembus(.base, weight: .semibold))
                            .padding(.horizontal, Space.s6)
                            .padding(.vertical, Space.s4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.theme(.surfaceSunken))
                            .accessibilityAddTraits(.isHeader)
                        hairline
                    }
                }
                VStack(alignment: .leading, spacing: Space.s0) { content }
                    .font(.trembus(.base))
                    .padding(Space.s6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Group(subviews: footer) { views in
                    if !views.isEmpty {
                        hairline
                        HStack(spacing: Space.s3) {
                            Spacer(minLength: Space.s0)
                            views
                        }
                        .padding(.horizontal, Space.s6)
                        .padding(.vertical, Space.s4)
                        .background(.theme(.surfaceSunken))
                    }
                }
            }
            .foregroundStyle(.theme(.text))
            // Only the card that IS the button's label answers the pointer; cards inside it stay at rest.
            .environment(\.cardInteraction, .rest)
        }
        .accessibilityElement(children: .contain)
    }

    private var hairline: some View {
        Rectangle().fill(.theme(.borderSoft)).frame(height: 1)
    }
}

extension InteractionState {
    /// Hover lifts a pressable card; pressing settles it back down but keeps the firm edge,
    /// so rest ≠ hover ≠ pressed even in a still.
    var cardEmphasis: SurfaceEmphasis {
        switch phase {
        case .hover: .lifted
        case .pressed: .firm
        case .rest, .disabled: .none
        }
    }
}

extension Card where Header == EmptyView, Footer == EmptyView {
    public init(@ViewBuilder content: () -> Content) {
        self.init(header: EmptyView(), content: content(), footer: EmptyView())
    }
}

extension Card where Footer == EmptyView {
    public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
        self.init(header: header(), content: content(), footer: EmptyView())
    }
}

extension Card where Header == EmptyView {
    public init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.init(header: EmptyView(), content: content(), footer: footer())
    }
}

extension Card where Header == Text, Footer == EmptyView {
    /// `Card("Storage") { … }` — a plain-text header.
    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(header: Text(title), content: content(), footer: EmptyView())
    }
}

extension Card where Header == Text {
    public init(_ title: String, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.init(header: Text(title), content: content(), footer: footer())
    }
}
