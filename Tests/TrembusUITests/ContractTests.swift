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
                .flatMap { patterns(in: $0).filter { $0.hasPrefix("\\b") } }
        }
        return units
    }

    @Test func buildsOnMatchesWhatTheSourceReallyUses() throws {
        let units = Self.unitPatterns
        #expect(units["Surface"] != nil, "found no primitives — is the path right?")
        for entry in Self.componentEntries {
            guard let contract = entry.contract else { continue }
            // Comment lines are dropped: a usage example in a doc comment is not a dependency.
            let source = Self.swiftSources(in: Self.componentsDirectory.appendingPathComponent(entry.name))
                .joined(separator: "\n").split(separator: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
                .joined(separator: "\n")
            var used: Set<String> = []
            for (unit, patterns) in units where unit != entry.name {
                // NSRegularExpression on purpose: Swift Regex's `\\b` follows Unicode word rules, where the
                // "." in `ControlMetrics.button` does NOT end a word.
                let isUsed = try patterns.contains {
                    try NSRegularExpression(pattern: $0)
                        .firstMatch(in: source, range: NSRange(source.startIndex..., in: source)) != nil
                }
                if isUsed { used.insert(unit) }
            }
            #expect(
                Set(contract.buildsOn) == used,
                "\(entry.name).buildsOn says \(contract.buildsOn.sorted()) but its source uses \(used.sorted())")
        }
    }

    @Test func neighborsWalkBuildsOnBackwards() {
        let ofSurface = Catalog.neighbors(of: "Surface").map(\.name)
        #expect(ofSurface.contains("Card"))
        #expect(!ofSurface.contains("Surface"))
        #expect(Catalog.neighbors(of: "NoSuchThing").isEmpty)
    }

    // MARK: - Form: the shared meaning (authored on the web, mirrored here)

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

    /// The drift signal. The web contract is the source of truth; this Shape mirrors it word for word.
    @Test func everyFormMirrorsTheWebContractWordForWord() throws {
        for entry in Self.componentEntries {
            guard let form = entry.contract?.form else { continue }
            let file = Self.webComponentsDirectory.appendingPathComponent("\(entry.name)/\(entry.name).contract.ts")
            guard let web = try? String(contentsOf: file, encoding: .utf8) else { continue }
            // Compare on text only: TS wraps long strings across lines and quotes them differently.
            let flat = web.replacing(/['"`]\s*\+?\s*\n\s*['"`]/, with: "").replacing(/\s+/, with: " ")
            for sentence in [form.id, "revision: '\(form.revision)'", form.meaning] + form.invariants
                + form.prohibitions + form.variation
            {
                #expect(
                    flat.contains(sentence.replacing("'", with: "\\'")) || flat.contains(sentence),
                    "\(entry.name) form has drifted from \(file.lastPathComponent): '\(sentence)' is not there")
            }
        }
    }
}
