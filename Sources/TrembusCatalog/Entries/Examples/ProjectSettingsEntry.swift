import SwiftUI
import TrembusTokens
import TrembusUI

// An EXAMPLE is a mockup: several components composed into one screen. It has no contract — the
// question it answers is not "does this do the three jobs" but "do these sit well TOGETHER":
// do the heights line up, does the spacing hold, does a whole-screen state (invalid, saving) read
// as one thing in every theme. It reaches the library through `import TrembusUI` only, exactly as
// a consumer does, so it also proves the public API is enough to build a real screen.

extension CatalogEntry {
    static let projectSettings = CatalogEntry(
        name: "ProjectSettings",
        kind: .example,
        summary: "A settings pane: every component on one card, in the screen states a real form goes through.",
        composes: ["Badge", "Button", "Card", "Input", "Meter", "Switch"],
        specimens: [
            Specimen("Default", note: "the happy path — a saved project, nothing wrong") {
                ProjectSettings(form: .saved)
            },
            Specimen("States", note: "SCREEN states, not control states: empty · invalid · saving") {
                HStack(alignment: .top, spacing: Space.s5) {
                    Labeled("empty") { ProjectSettings(form: .empty) }
                    Labeled("invalid") { ProjectSettings(form: .invalid) }
                    Labeled("saving") { ProjectSettings(form: .saving) }
                }
            },
            Specimen("Interaction", note: "live — clear the name, flip a switch, press Save") {
                ProjectSettingsPlayground()
            },
        ])
}

/// Everything the pane shows, as plain data — so one layout serves the stills and the live one.
private struct ProjectForm {
    var name: String
    var email: String
    var deploysOnPush: Bool
    var requiresReview: Bool
    var storage: Double
    var hasTriedToSave = false
    var isSaving = false

    static let saved = ProjectForm(
        name: "trembus-swift", email: "ada@example.com", deploysOnPush: true, requiresReview: false, storage: 0.64)
    static let empty = ProjectForm(name: "", email: "", deploysOnPush: false, requiresReview: false, storage: 0)
    static let invalid = ProjectForm(
        name: "", email: "ada@", deploysOnPush: true, requiresReview: true, storage: 0.93, hasTriedToSave: true)
    static let saving = ProjectForm(
        name: "trembus-swift", email: "ada@example.com", deploysOnPush: true, requiresReview: true, storage: 0.64,
        isSaving: true)

    /// Nothing is "wrong" until you have tried to save.
    var nameError: String? { hasTriedToSave && name.isEmpty ? "A project needs a name." : nil }
    var emailError: String? {
        hasTriedToSave && !email.isEmpty && !email.contains(".") ? "Enter a full email address." : nil
    }
    var isValid: Bool { !name.isEmpty && (email.isEmpty || email.contains(".")) }
    var isNearlyFull: Bool { storage >= 0.9 }
}

private struct ProjectSettings: View {
    @Binding private var form: ProjectForm
    private let onSave: () -> Void

    init(form: Binding<ProjectForm>, onSave: @escaping () -> Void = {}) {
        self._form = form
        self.onSave = onSave
    }

    /// A still: the form never changes.
    init(form: ProjectForm) {
        self.init(form: .constant(form))
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Space.s5) {
                Input(
                    "Project name", text: $form.name, prompt: "my-project",
                    description: "Shown in the sidebar and in URLs.", error: form.nameError, isRequired: true)
                Input("Owner email", text: $form.email, prompt: "you@example.com", error: form.emailError) {
                    Image(systemName: "envelope")
                }
                VStack(alignment: .leading, spacing: Space.s4) {
                    Toggle("Deploy on push", isOn: $form.deploysOnPush).toggleStyle(.trembus)
                    Toggle("Require a review", isOn: $form.requiresReview).toggleStyle(.trembus)
                }
                Meter(
                    value: form.storage, tone: .fixed(form.isNearlyFull ? .danger : .accent), label: "Storage",
                    showsValue: true)
            }
            .disabled(form.isSaving)
        } header: {
            HStack(spacing: Space.s3) {
                Text("Project")
                status
            }
        } footer: {
            Button("Cancel") {}.buttonStyle(.trembus(.ghost)).disabled(form.isSaving)
            Button("Save", action: onSave).buttonStyle(.trembus(isLoading: form.isSaving))
        }
        .frame(width: ProjectSettingsSpecimen.width)
    }

    /// The header badge sums the whole pane up in one word — tone is never the only signal.
    @ViewBuilder private var status: some View {
        if form.isSaving {
            Badge("Saving", tone: .info, showsDot: true)
        } else if form.nameError != nil || form.emailError != nil {
            Badge("Needs attention", tone: .danger, showsDot: true)
        } else if form.isNearlyFull {
            Badge("Nearly full", tone: .warning, showsDot: true)
        } else if form.name.isEmpty {
            Badge("Draft")
        } else {
            Badge("Live", tone: .success, showsDot: true)
        }
    }
}

private enum ProjectSettingsSpecimen {
    static let width: CGFloat = 320
}

private struct ProjectSettingsPlayground: View {
    @State private var form = ProjectForm.saved
    @State private var saves = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            ProjectSettings(form: $form) {
                form.hasTriedToSave = true
                if form.isValid { saves += 1 }
            }
            Text(saves == 0 ? "Not saved yet" : "Saved \(saves)×")
                .font(.trembus(.sm))
                .foregroundStyle(.theme(.textDim))
        }
    }
}

struct ProjectSettingsEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.projectSettings) }
}
