import Foundation
import Testing

@testable import TrembusCatalog

// The contract gate — the Swift `check-contracts`. A component cannot ship without saying
// how it does the three UI jobs, and every claim must point at a specimen that exists.

@Suite("Contract gate")
struct ContractTests {
    /// `Sources/TrembusUI/Components/`, found relative to this file.
    static let componentsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/TrembusUI/Components", isDirectory: true)

    static var componentDirectoryNames: [String] {
        let urls =
            (try? FileManager.default.contentsOfDirectory(
                at: componentsDirectory, includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles])) ?? []
        return urls.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map(\.lastPathComponent).sorted()
    }

    static var componentEntries: [CatalogEntry] { Catalog.entries(of: .component) }

    @Test func everyComponentDirectoryHasACatalogEntry() {
        let registered = Set(Self.componentEntries.map(\.name))
        #expect(!Self.componentDirectoryNames.isEmpty, "found no component directories — is the path right?")
        for directory in Self.componentDirectoryNames {
            #expect(
                registered.contains(directory),
                "Components/\(directory)/ has no catalog entry. Add Entries/Components/\(directory)Entry.swift and list it in Catalog.entries."
            )
        }
    }

    @Test func everyComponentEntryHasADirectory() {
        let directories = Set(Self.componentDirectoryNames)
        for entry in Self.componentEntries {
            #expect(
                directories.contains(entry.name),
                "catalog entry '\(entry.name)' has no Components/\(entry.name)/ directory")
        }
    }

    @Test func entryNamesAreUnique() {
        let names = Catalog.entries.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test func everyComponentDeclaresAContractUnderItsOwnName() {
        for entry in Self.componentEntries {
            #expect(entry.contract != nil, "\(entry.name) has no contract")
            #expect(entry.contract?.name == entry.name, "\(entry.name): contract.name must equal the directory name")
        }
    }

    @Test func everyComponentShipsTheThreeStandardSpecimens() {
        for entry in Self.componentEntries {
            for name in Specimen.standardNames {
                #expect(entry.specimen(named: name) != nil, "\(entry.name) is missing the '\(name)' specimen")
            }
        }
    }

    @Test func everyJobPointsAtARealSpecimenAndSaysHow() {
        for entry in Self.componentEntries {
            guard let contract = entry.contract else { continue }
            for job in UIJob.allCases {
                let satisfaction = contract.satisfaction(for: job)
                #expect(
                    entry.specimen(named: satisfaction.specimen) != nil,
                    "\(entry.name).\(job.rawValue) points at specimen '\(satisfaction.specimen)', which doesn't exist")
                let statement = satisfaction.satisfiedBy.trimmingCharacters(in: .whitespacesAndNewlines)
                #expect(
                    statement.count >= 20 && !statement.localizedCaseInsensitiveContains("TODO"),
                    "\(entry.name).\(job.rawValue): say HOW in a real sentence (still a TODO or too short)")
            }
        }
    }

    @Test func specimenNamesAreUniqueWithinAnEntry() {
        for entry in Catalog.entries {
            let names = entry.specimens.map(\.name)
            #expect(Set(names).count == names.count, "\(entry.name) has duplicate specimen names")
            #expect(!names.isEmpty, "\(entry.name) has no specimens")
        }
    }

    @Test func interactiveComponentsClaimAFocusRingAndKeys() {
        for entry in Self.componentEntries {
            guard let contract = entry.contract, contract.leadJob != .revealState else { continue }
            #expect(contract.a11y.focusRing, "\(entry.name) leads with an interactive job but claims no focus ring")
            #expect(!contract.a11y.keyboard.isEmpty, "\(entry.name) leads with an interactive job but lists no keys")
        }
    }

    /// House rule: `.motion(_:value:)`, never bare `.animation` — the wrapper is what honors Reduce Motion.
    /// (Found in review: the shared Spinner used a bare one, so it spun on with Reduce Motion on.)
    @Test func theLibraryNeverAnimatesAroundReduceMotion() throws {
        let library = Self.componentsDirectory.deletingLastPathComponent()
        let files = try #require(FileManager.default.enumerator(at: library, includingPropertiesForKeys: nil))
        for case let file as URL in files where file.pathExtension == "swift" {
            guard file.lastPathComponent != "MotionModifiers.swift" else { continue }  // the one place allowed to
            let source = try String(contentsOf: file, encoding: .utf8)
            for (number, line) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
            where line.contains(".animation(") && !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                Issue.record("\(file.lastPathComponent):\(number + 1) uses a bare .animation — use .motion(_:value:)")
            }
        }
    }

    // MARK: - Shape: what each component is built from (Harmonics walks this)

    static let primitivesDirectory = componentsDirectory.deletingLastPathComponent()
        .appendingPathComponent("Primitives", isDirectory: true)

    static func swiftSources(in directory: URL) -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "swift" }.compactMap { try? String(contentsOf: $0, encoding: .utf8) }
    }

    /// Every buildable unit → the patterns that mean "this source uses it": its top-level type
    /// names as words, and its public modifiers as `.name(` calls.
    static var unitPatterns: [String: [String]] {
        var units: [String: [String]] = [:]
        func patterns(in source: String) -> [String] {
            let types = source.matches(
                of: /(?m)^(?:nonisolated )?(?:public )?(?:struct|enum|protocol|final class|class) (\w+)/
            )
            .map { "\\b\($0.1)\\b" }
            let modifiers = source.matches(of: /(?m)^\s+public func (\w+)\(/).map { "\\.\($0.1)\\(" }
            return types + modifiers
        }
        let files =
            (try? FileManager.default.contentsOfDirectory(at: primitivesDirectory, includingPropertiesForKeys: nil))
            ?? []
        for file in files where file.pathExtension == "swift" {
            guard let source = try? String(contentsOf: file, encoding: .utf8) else { continue }
            units[file.deletingPathExtension().lastPathComponent] = patterns(in: source)
        }
        for directory in componentDirectoryNames {
            units[directory] = swiftSources(in: componentsDirectory.appendingPathComponent(directory))
                .flatMap { patterns(in: $0).filter { $0.hasPrefix("\\b") } + stylePatterns(in: $0) }
        }
        return units
    }

    /// A style component is never named where it is used — `.buttonStyle(.trembus)` — so its pattern is
    /// the modifier plus the static member, read from `extension ButtonStyle where Self == …`.
    static func stylePatterns(in source: String) -> [String] {
        source.matches(of: /(?ms)^extension (\w+Style) where Self == \w+ \{(.*?)^\}/).flatMap { match in
            let modifier = match.1.prefix(1).lowercased() + match.1.dropFirst()
            let members = Set(match.2.matches(of: /public static (?:var|func) (\w+)/).map { String($0.1) })
            return members.sorted().map { "\\.\(modifier)\\(\\s*\\.\($0)\\b" }
        }
    }

    /// The units (primitive files + components) that `sources` really use, leaving out `own`.
    /// Comment lines are dropped: a usage example in a doc comment is not a dependency. So is the inside
    /// of every string literal — a name in a specimen `note:`, or in an example's own `composes:` list
    /// (which sits in the very file being read), must not count as a use.
    static func unitsUsed(in sources: [String], except own: String? = nil) throws -> Set<String> {
        let source = sources.joined(separator: "\n").split(separator: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
            .replacing(/"(?:[^"\\\n]|\\.)*"/, with: "\"\"")
        var used: Set<String> = []
        for (unit, patterns) in unitPatterns where unit != own {
            // NSRegularExpression on purpose: Swift Regex's `\\b` follows Unicode word rules, where the
            // "." in `ControlMetrics.button` does NOT end a word.
            let isUsed = try patterns.contains {
                try NSRegularExpression(pattern: $0)
                    .firstMatch(in: source, range: NSRange(source.startIndex..., in: source)) != nil
            }
            if isUsed { used.insert(unit) }
        }
        return used
    }

    @Test func buildsOnMatchesWhatTheSourceReallyUses() throws {
        #expect(Self.unitPatterns["Surface"] != nil, "found no primitives — is the path right?")
        for entry in Self.componentEntries {
            guard let contract = entry.contract else { continue }
            var used = try Self.unitsUsed(
                in: Self.swiftSources(in: Self.componentsDirectory.appendingPathComponent(entry.name)),
                except: entry.name)
            // One step through the primitives too: a ring drawn by `FieldShell` is still a ring on Input.
            // Primitives have no catalog entry, so without this `make neighbors NAME=FocusRing` would
            // stop at FieldShell and never reach the fields that wear it.
            for primitive in used {
                let file = Self.primitivesDirectory.appendingPathComponent(primitive + ".swift")
                guard let source = try? String(contentsOf: file, encoding: .utf8) else { continue }
                // Primitives only: `ControlMetrics` has a table NAMED after every component it sizes.
                let reached = try Self.unitsUsed(in: [source], except: primitive).filter {
                    FileManager.default.fileExists(
                        atPath: Self.primitivesDirectory.appendingPathComponent($0 + ".swift").path)
                }
                used.formUnion(reached)
            }
            used.remove(entry.name)
            #expect(
                Set(contract.buildsOn) == used,
                "\(entry.name).buildsOn says \(contract.buildsOn.sorted()) but its source uses \(used.sorted())")
        }
    }

    @Test func styleComponentsAreFoundByTheirModifier() throws {
        let button = try #require(Self.unitPatterns["Button"])
        func uses(_ call: String) throws -> Bool {
            try button.contains {
                try NSRegularExpression(pattern: $0).firstMatch(in: call, range: NSRange(call.startIndex..., in: call))
                    != nil
            }
        }
        #expect(try uses("Button(\"Save\") {}.buttonStyle(.trembus)"))
        #expect(try uses("Button(\"More\") {}.buttonStyle(.trembus(.ghost))"))
        #expect(try !uses("Button {} label: { card }.buttonStyle(.trembusCard)"), "that one is Card's")
        #expect(try !uses("Toggle(\"Sync\", isOn: $sync).toggleStyle(.trembus)"), "that one is Switch's")
        #expect(try !uses("Text(\"Save\").font(.trembus(.sm))"))
    }

    @Test func neighborsWalkBuildsOnBackwards() {
        let ofSurface = Catalog.neighbors(of: "Surface").map(\.name)
        #expect(ofSurface.contains("Card"))
        #expect(!ofSurface.contains("Surface"))
        #expect(Catalog.neighbors(of: "NoSuchThing").isEmpty)
    }

    // MARK: - Examples: mockups of several components together (no contract, a different gate)

    /// `Sources/TrembusCatalog/Entries/Examples/`.
    static let examplesDirectory =
        componentsDirectory
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("TrembusCatalog/Entries/Examples", isDirectory: true)

    static var exampleEntries: [CatalogEntry] { Catalog.entries(of: .example) }

    static func exampleFile(_ name: String) -> URL { examplesDirectory.appendingPathComponent("\(name)Entry.swift") }

    @Test func everyExampleFileHasACatalogEntryAndBack() {
        let files =
            (try? FileManager.default.contentsOfDirectory(at: Self.examplesDirectory, includingPropertiesForKeys: nil))
            ?? []
        let onDisk = Set(
            files.map(\.lastPathComponent).filter { $0.hasSuffix("Entry.swift") }.map { String($0.dropLast(11)) })
        let registered = Set(Self.exampleEntries.map(\.name))
        #expect(!onDisk.isEmpty, "found no example files — is the path right?")
        for name in onDisk.subtracting(registered).sorted() {
            Issue.record(
                "Entries/Examples/\(name)Entry.swift is not listed in Catalog.entries as an example named '\(name)'")
        }
        for name in registered.subtracting(onDisk).sorted() {
            Issue.record("example '\(name)' has no Entries/Examples/\(name)Entry.swift")
        }
    }

    @Test func examplesCarryNoContractAndOnlyExamplesCompose() {
        for entry in Catalog.entries {
            if entry.kind == .example {
                #expect(
                    entry.contract == nil,
                    "\(entry.name): an example has no three-jobs story — drop the contract, or make it a component")
            } else {
                #expect(
                    entry.composes.isEmpty,
                    "\(entry.name): `composes` is for examples; a component says `buildsOn` in its contract")
            }
        }
    }

    @Test func anExampleComposesAtLeastTwoComponents() {
        let components = Set(Self.componentEntries.map(\.name))
        for entry in Self.exampleEntries {
            #expect(
                components.intersection(entry.composes).count >= 2,
                "\(entry.name) composes \(entry.composes) — one component alone is a specimen of that component, not an example"
            )
        }
    }

    @Test func composesMatchesWhatTheExampleReallyUses() throws {
        for entry in Self.exampleEntries {
            guard let source = try? String(contentsOf: Self.exampleFile(entry.name), encoding: .utf8) else { continue }
            let used = try Self.unitsUsed(in: [source])
            #expect(
                Set(entry.composes) == used,
                "\(entry.name).composes says \(entry.composes.sorted()) but its source uses \(used.sorted())")
        }
    }

    /// An example's entry file holds its own `composes:` list. If a name inside a string counted as a
    /// use, that list would vouch for itself: delete the `Badge(…)` call, keep "Badge" in the list, and
    /// the gate would stay green. (Found in review of the PR that added examples.)
    @Test func aNameInsideAStringIsNotAUse() throws {
        let listedButNeverCalled = """
            composes: ["Badge", "Meter"],
            specimens: [
                Specimen("Default", note: "a Card with a Badge — Text(\\"Surface\\")") { Meter(value: 0.5) }
            ]
            """
        #expect(try Self.unitsUsed(in: [listedButNeverCalled]) == ["Meter"])
        // Code between two strings on one line is still code.
        #expect(try Self.unitsUsed(in: ["Labeled(\"a\") { Badge(\"b\") }"]) == ["Badge"])
    }

    @Test func neighborsReachTheExamples() {
        #expect(Catalog.neighbors(of: "Input").map(\.name).contains("ProjectSettings"))
        // Two hops: Surface → Card → the example that composes Card.
        #expect(Catalog.neighbors(of: "Surface").contains { $0.name == "ProjectSettings" && $0.distance == 2 })
        #expect(Catalog.neighbors(of: "ProjectSettings").isEmpty, "nothing builds on an example")
    }

    // MARK: - Form: the shared meaning (authored here; compared with the web, read-only, where it has one)

    @Test func everyFormIsWellFormed() {
        for entry in Self.componentEntries {
            guard let form = entry.contract?.form else { continue }
            #expect(form.id == "form." + entry.name.lowercased(), "\(entry.name): form id must be form.<name>")
            #expect(!form.revision.isEmpty, "\(entry.name): a Form pins a revision")
            #expect(!form.invariants.isEmpty, "\(entry.name): a Form with no invariants preserves nothing")
            for sentence in [form.meaning] + form.invariants + form.prohibitions + form.variation
                + form.relationships.map(\.note)
            {
                #expect(
                    sentence.count >= 20 && !sentence.localizedCaseInsensitiveContains("TODO"),
                    "\(entry.name) form: '\(sentence)' is not a real sentence yet")
            }
            for relationship in form.relationships {
                #expect(relationship.target.hasPrefix("form."), "\(entry.name): relationships point at Form ids")
                #expect(relationship.target != form.id, "\(entry.name): a Form cannot relate to itself")
            }
        }
    }

    /// `../Trembus-Component-Library`, when it is checked out next door (it is not on CI).
    static let webComponentsDirectory =
        componentsDirectory
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Trembus-Component-Library/packages/ui/src/components", isDirectory: true)

    /// A component that goes by another name next door. Without this the drift check would look for
    /// `Waveform/Waveform.contract.ts`, find nothing, and stay green whatever the web's Form came to say.
    static let webNames = ["Waveform": "AudioWaveform"]

    static func webContractFile(for name: String) -> URL {
        let web = webNames[name] ?? name
        return webComponentsDirectory.appendingPathComponent("\(web)/\(web).contract.ts")
    }

    @Test func aComponentRenamedNextDoorIsStillPairedWithItsWebContract() {
        #expect(Self.webContractFile(for: "Waveform").lastPathComponent == "AudioWaveform.contract.ts")
        #expect(Self.webContractFile(for: "Card").lastPathComponent == "Card.contract.ts")
        for (name, _) in Self.webNames {
            #expect(Self.componentEntries.contains { $0.name == name }, "\(name) is paired but is not a component here")
        }
        // The other half only bites where the web repo is checked out (it is not on CI): a pairing that
        // points at nothing would quietly switch the drift check off.
        guard FileManager.default.fileExists(atPath: Self.webComponentsDirectory.path) else { return }
        for (name, _) in Self.webNames {
            let file = Self.webContractFile(for: name)
            #expect(FileManager.default.fileExists(atPath: file.path), "\(name) is paired with a missing \(file.path)")
        }
    }

    /// The drift signal, READ-ONLY. This repo never writes next door. A Form may be authored here (the web
    /// has none yet — nothing to compare) or the web may already hold one (Card); then the two must say the
    /// same thing, in BOTH directions. A difference is reported for a human to settle; it is never "fixed"
    /// by editing the web repo from here.
    @Test func aFormTheWebAlsoHasSaysTheSameThing() throws {
        for entry in Self.componentEntries {
            guard let form = entry.contract?.form else { continue }
            let file = Self.webContractFile(for: entry.name)
            guard let web = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let webStrings = Self.formStrings(inWebContract: web)
            guard !webStrings.isEmpty else { continue }  // authored here; the web has no Form to drift from
            let mirrored = Set(
                [form.id, form.revision, form.meaning] + form.invariants + form.prohibitions + form.variation
                    + form.relationships.flatMap { [$0.kind.rawValue, $0.target, $0.note] })
            for missing in mirrored.subtracting(webStrings).sorted() {
                Issue.record(
                    "\(entry.name) form has drifted: '\(missing)' is here but not in \(file.lastPathComponent)")
            }
            for missing in webStrings.subtracting(mirrored).sorted() {
                Issue.record(
                    "\(entry.name) form has drifted: '\(missing)' is in \(file.lastPathComponent) but not here")
            }
        }
    }

    /// Every string literal inside the web contract's `form: { … }` block, with `'a' + 'b'` joined
    /// and escapes undone. The block runs to the end of the object, so `form` must stay the LAST field.
    static func formStrings(inWebContract source: String) -> Set<String> {
        guard let start = source.range(of: "form: {") else { return [] }
        let block = String(source[start.upperBound...])
            .replacing(/['"`]\s*\+\s*['"`]/, with: "")
        var strings: Set<String> = []
        for match in block.matches(of: /'((?:[^'\\]|\\.)*)'/) {
            strings.insert(String(match.1).replacing("\\'", with: "'"))
        }
        return strings
    }

    @Test func theWebFormParserSeesEverySentenceAndOnlyTheFormBlock() {
        let web = """
            export const c = {
              name: 'Card',
              form: {
                id: 'form.card',
                invariants: ['One.', 'A long ' +
                  'sentence.', 'It\\'s escaped.'],
              },
            };
            """
        #expect(Self.formStrings(inWebContract: web) == ["form.card", "One.", "A long sentence.", "It's escaped."])
        #expect(Self.formStrings(inWebContract: "export const c = { name: 'Card' };").isEmpty)
    }

    @Test func neighborsHonorTheHopLimit() {
        #expect(Catalog.neighbors(of: "Surface", hops: 0).isEmpty)
        #expect(Catalog.neighbors(of: "Surface", hops: -1).isEmpty)
        #expect(Catalog.neighbors(of: "Surface", hops: 1).map(\.name) == ["Card"])
    }
}
