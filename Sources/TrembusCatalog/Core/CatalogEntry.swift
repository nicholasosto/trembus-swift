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
        /// A mockup: several components composed into one screen. No contract — it has no single
        /// three-jobs story. Gated differently: it lists what it `composes`, and it must render.
        case example = "Examples"
    }

    public let name: String
    public let kind: Kind
    public let summary: String
    public let contract: ComponentContract?
    /// Examples only: the primitives + components the mockup is made of. The gate checks it against
    /// the entry's source, the same way it checks a component's `buildsOn`.
    public let composes: [String]
    public let specimens: [Specimen]

    public var id: String { name }

    public init(
        name: String, kind: Kind, summary: String, contract: ComponentContract? = nil,
        composes: [String] = [], specimens: [Specimen]
    ) {
        self.name = name
        self.kind = kind
        self.summary = summary
        self.contract = contract
        self.composes = composes
        self.specimens = specimens
    }

    /// What Harmonics walks: a component's `buildsOn`, an example's `composes`.
    public var madeOf: [String] { contract?.buildsOn ?? composes }

    public func specimen(named name: String) -> Specimen? {
        specimens.first { $0.name == name }
    }
}
