import Foundation

// The first-principles contract — the same shape as `ComponentContract` in
// `@trembus/tokens/contract`. Because the three jobs are non-optional fields, a component
// literally cannot be registered without saying how it does each one. `ContractTests`
// then checks that every claim points at a specimen that really exists.

/// The three irreducible jobs of any UI.
nonisolated public enum UIJob: String, CaseIterable, Sendable {
    case revealState = "reveal-state"
    case affordAction = "afford-action"
    case acknowledgeInput = "acknowledge-input"

    public var title: String {
        switch self {
        case .revealState: "Reveal State"
        case .affordAction: "Afford Action"
        case .acknowledgeInput: "Acknowledge Input"
        }
    }

    /// The question a person is silently asking when this job matters.
    public var question: String {
        switch self {
        case .revealState: "What is true right now?"
        case .affordAction: "What can I do here?"
        case .acknowledgeInput: "Did it hear me?"
        }
    }

    public var symbolName: String {
        switch self {
        case .revealState: "eye"
        case .affordAction: "hand.point.up.left"
        case .acknowledgeInput: "arrow.uturn.backward.circle"
        }
    }
}

nonisolated public struct JobSatisfaction: Sendable, Hashable {
    /// Plain-language statement of HOW this component does the job.
    public var satisfiedBy: String
    /// Exact name of the specimen that DEMONSTRATES it.
    public var specimen: String

    public init(_ satisfiedBy: String, specimen: String) {
        self.satisfiedBy = satisfiedBy
        self.specimen = specimen
    }
}

/// What a component IS, apart from how any one platform draws it — a Relay-style *Form*.
///
///     Form      meaning + invariants + prohibitions + permitted variation   (shared, authored on the web)
///      └▶ Shape     one expression of it: the React component, this SwiftUI one
///          └▶ Instance  one real use: a specimen, a card on a consumer's screen
///
/// **The web contract is the source of truth**, exactly like the tokens: a Form is authored in
/// `<Name>.contract.ts` next door and mirrored here word for word. `ContractTests` compares the two
/// when the sibling checkout is present. Changing meaning or an invariant is a NEW revision there first.
nonisolated public struct ComponentForm: Sendable, Hashable, Codable {
    /// A meaning-level link to another Form. Authored, never inferred; it says "review these
    /// together", not "this causes that".
    public struct Relationship: Sendable, Hashable, Codable {
        public enum Kind: String, Sendable, Codable {
            case distinctFrom, relatedTo
        }

        public var kind: Kind
        /// The other Form's id, e.g. `form.dialog`. It may not have a Swift Shape yet.
        public var target: String
        public var note: String

        public init(_ kind: Kind, _ target: String, note: String) {
            self.kind = kind
            self.target = target
            self.note = note
        }
    }

    /// `form.<name, lowercased>`.
    public var id: String
    /// The web revision this Shape mirrors, e.g. `r1`.
    public var revision: String
    /// One sentence: what a result of this Form must mean.
    public var meaning: String
    /// What every Shape must preserve. Each one should be checkable — by a test or by eye on the sheet.
    public var invariants: [String]
    /// What no Shape may do.
    public var prohibitions: [String]
    /// Where Shapes are free to differ.
    public var variation: [String]
    public var relationships: [Relationship]

    public init(
        id: String, revision: String, meaning: String, invariants: [String], prohibitions: [String] = [],
        variation: [String] = [], relationships: [Relationship] = []
    ) {
        self.id = id
        self.revision = revision
        self.meaning = meaning
        self.invariants = invariants
        self.prohibitions = prohibitions
        self.variation = variation
        self.relationships = relationships
    }
}

nonisolated public struct ComponentContract: Sendable, Hashable {
    public struct Accessibility: Sendable, Hashable {
        public var role: String?
        public var keyboard: [String]
        public var focusRing: Bool

        public init(role: String? = nil, keyboard: [String] = [], focusRing: Bool = false) {
            self.role = role
            self.keyboard = keyboard
            self.focusRing = focusRing
        }
    }

    /// Must equal the component's directory name under `Sources/TrembusUI/Components/`.
    public var name: String
    /// The job this component leads with. It still does all three.
    public var leadJob: UIJob
    /// Make machine/data state perceivable.
    public var revealState: JobSatisfaction
    /// Expose capability with a visible affordance.
    public var affordAction: JobSatisfaction
    /// Respond perceivably to every input — close the feedback loop.
    public var acknowledgeInput: JobSatisfaction
    public var a11y: Accessibility
    /// Token families this component reads.
    public var tokensUsed: [String]
    /// Shape-level: the primitives (file names under `Primitives/`) and components this SwiftUI
    /// expression is made of. `ContractTests` checks it against the source, so it cannot rot —
    /// and `make neighbors NAME=X` walks it backwards to say what to re-look at when X changes.
    public var buildsOn: [String]
    /// The shared meaning this component expresses. `nil` until its Form is authored on the web.
    public var form: ComponentForm?

    public init(
        name: String, leadJob: UIJob, revealState: JobSatisfaction, affordAction: JobSatisfaction,
        acknowledgeInput: JobSatisfaction, a11y: Accessibility = .init(), tokensUsed: [String] = [],
        buildsOn: [String] = [], form: ComponentForm? = nil
    ) {
        self.name = name
        self.leadJob = leadJob
        self.revealState = revealState
        self.affordAction = affordAction
        self.acknowledgeInput = acknowledgeInput
        self.a11y = a11y
        self.tokensUsed = tokensUsed
        self.buildsOn = buildsOn
        self.form = form
    }

    public func satisfaction(for job: UIJob) -> JobSatisfaction {
        switch job {
        case .revealState: revealState
        case .affordAction: affordAction
        case .acknowledgeInput: acknowledgeInput
        }
    }
}
