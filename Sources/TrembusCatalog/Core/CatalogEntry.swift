import SwiftUI
import TrembusTokens
import TrembusUI

/// One named, self-contained demonstration of a component — a Storybook "story".
///
/// A specimen must have a definite size (give flexible views a `.frame(width:)`), and must
/// look right as a STILL image: freeze hover/pressed with `.interactionOverride(_:)`.
public struct Specimen: Identifiable {
    /// The three every component must ship. Contracts point at these by name.
    public static let standardNames = ["Default", "States", "Interaction"]

    public let name: String
    public let note: String
    public let content: () -> AnyView

    public var id: String { name }

    public init<V: View>(_ name: String, note: String = "", @ViewBuilder content: @escaping () -> V) {
        self.name = name
        self.note = note
        self.content = { AnyView(content()) }
    }
}

/// Everything the catalog knows about one thing: what it is, its contract, its specimens.
public struct CatalogEntry: Identifiable {
    public enum Kind: String, CaseIterable, Sendable {
        /// Pictures of the tokens themselves. No contract.
        case foundation = "Foundations"
        /// Building blocks the components are made of. No contract.
        case primitive = "Primitives"
        /// Gated: needs a contract and the three standard specimens.
        case component = "Components"
    }

    public let name: String
    public let kind: Kind
    public let summary: String
    public let contract: ComponentContract?
    public let specimens: [Specimen]

    public var id: String { name }

    public init(
        name: String, kind: Kind, summary: String, contract: ComponentContract? = nil,
        specimens: [Specimen]
    ) {
        self.name = name
        self.kind = kind
        self.summary = summary
        self.contract = contract
        self.specimens = specimens
    }

    public func specimen(named name: String) -> Specimen? {
        specimens.first { $0.name == name }
    }
}
