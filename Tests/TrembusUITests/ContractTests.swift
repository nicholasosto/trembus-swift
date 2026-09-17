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
}
