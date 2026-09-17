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

    public init(
        name: String, leadJob: UIJob, revealState: JobSatisfaction, affordAction: JobSatisfaction,
        acknowledgeInput: JobSatisfaction, a11y: Accessibility = .init(), tokensUsed: [String] = []
    ) {
        self.name = name
        self.leadJob = leadJob
        self.revealState = revealState
        self.affordAction = affordAction
        self.acknowledgeInput = acknowledgeInput
        self.a11y = a11y
        self.tokensUsed = tokensUsed
    }

    public func satisfaction(for job: UIJob) -> JobSatisfaction {
        switch job {
        case .revealState: revealState
        case .affordAction: affordAction
        case .acknowledgeInput: acknowledgeInput
        }
    }
}
