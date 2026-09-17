import AppKit
import Foundation
import SwiftUI
import TrembusCatalog
import TrembusTokens
import TrembusUI

// TrembusSnap — renders catalog specimens to PNG, headlessly.
//
//   swift run TrembusSnap                       every entry → Snapshots/<Entry>.png
//   swift run TrembusSnap Button Badge          just these
//   swift run TrembusSnap Button --singles      also Snapshots/Button/<Specimen>.<theme>.png
//   swift run TrembusSnap --theme dark          only one theme band per specimen
//   swift run TrembusSnap --list                what's in the catalog
//   swift run TrembusSnap --neighbors Surface   what to re-look at when Surface changes (no PNGs)
//   swift run TrembusSnap --forms               every Form + what each Shape builds on, as JSON
//
// One sheet per entry = every specimen × every theme in a single image.

struct Options {
    var names: [String] = []
    var outDirectory = "Snapshots"
    var scale: CGFloat = 2
    var themes = Theme.all
    var singles = false
    var list = false
    var neighborsOf: String?
    var forms = false
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("error: " + message + "\n").utf8))
    exit(2)
}

func parse(_ arguments: [String]) -> Options {
    var options = Options()
    var iterator = arguments.makeIterator()
    while let argument = iterator.next() {
        switch argument {
        case "--out":
            guard let value = iterator.next() else { fail("--out needs a directory") }
            options.outDirectory = value
        case "--scale":
            guard let value = iterator.next(), let scale = Double(value), (1...4).contains(scale) else {
                fail("--scale needs a number from 1 to 4")
            }
            options.scale = scale
        case "--theme":
            guard let value = iterator.next(), let theme = Theme.all.first(where: { $0.name == value })
            else { fail("--theme needs one of: " + Theme.all.map(\.name).joined(separator: ", ")) }
            options.themes = [theme]
        case "--singles": options.singles = true
        case "--list": options.list = true
        case "--neighbors":
            guard let value = iterator.next() else { fail("--neighbors needs a primitive or component name") }
            options.neighborsOf = value
        case "--forms": options.forms = true
        case "-h", "--help":
            print(
                "usage: TrembusSnap [Name …] [--singles] [--theme NAME] [--scale N] [--out DIR] [--list] [--neighbors NAME] [--forms]"
            )
            exit(0)
        default:
            if argument.hasPrefix("-") { fail("unknown option \(argument)") }
            options.names.append(argument)
        }
    }
    return options
}

let options = parse(Array(CommandLine.arguments.dropFirst()))

if options.list {
    for kind in CatalogEntry.Kind.allCases {
        print(kind.rawValue)
        for entry in Catalog.entries(of: kind) {
            print("  \(entry.name)  —  " + entry.specimens.map(\.name).joined(separator: " · "))
        }
    }
    exit(0)
}

// Harmonics: who builds on this, walked backwards two hops. Names only, one per line, so it pipes:
//   make snap NAME="$(make -s neighbors NAME=Surface | tr '\n' ' ')"   (make needs them on ONE line)
if let changed = options.neighborsOf {
    for neighbor in Catalog.neighbors(of: changed) { print(neighbor.name) }
    exit(0)
}

// Platonics: the Forms this library expresses, for a consumer (or a Relay House) to adopt. Read-only.
if options.forms {
    struct Export: Encodable {
        struct Shape: Encodable {
            let component: String
            let buildsOn: [String]
            let form: ComponentForm?
        }
        let library = "trembus-swift"
        let shapes: [Shape]
    }
    let export = Export(
        shapes: Catalog.entries(of: .component).compactMap { entry in
            entry.contract.map { .init(component: entry.name, buildsOn: $0.buildsOn.sorted(), form: $0.form) }
        })
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    guard let data = try? encoder.encode(export) else { fail("could not encode the forms") }
    print(String(decoding: data, as: UTF8.self))
    exit(0)
}

let entries: [CatalogEntry] =
    options.names.isEmpty
    ? Catalog.entries
    : options.names.map { name in
        guard let entry = Catalog.entry(named: name) else {
            fail("no catalog entry named '\(name)'. Try --list.")
        }
        return entry
    }

NSApplication.shared.setActivationPolicy(.prohibited)  // never show a Dock icon or a window

let root = URL(fileURLWithPath: options.outDirectory, isDirectory: true)
var failures = 0

func write(_ view: some View, to url: URL) {
    do {
        let output = try Snapshotter.png(of: view, scale: options.scale)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try output.png.write(to: url)
        let blank = output.inkCoverage == 0 ? "  ⚠︎ BLANK" : ""
        print("  \(url.relativePath)  \(Int(output.size.width))×\(Int(output.size.height)) pt\(blank)")
        if output.inkCoverage == 0 { failures += 1 }
    } catch {
        print("  \(url.relativePath)  ✗ \(error)")
        failures += 1
    }
}

for entry in entries {
    print(entry.name)
    write(EntrySheet(entry, themes: options.themes), to: root.appendingPathComponent("\(entry.name).png"))
    if options.singles {
        for specimen in entry.specimens {
            for theme in options.themes {
                write(
                    SpecimenStage(specimen, theme: theme).fixedSize(),
                    to: root.appendingPathComponent("\(entry.name)/\(specimen.name).\(theme.name).png"))
            }
        }
    }
}

if failures > 0 { fail("\(failures) snapshot(s) failed or came out blank") }
