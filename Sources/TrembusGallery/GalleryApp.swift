import AppKit
import SwiftUI
import TrembusCatalog
import TrembusTokens
import TrembusUI

// TrembusGallery — the live catalog. Snapshots show how a component LOOKS;
// this is where you find out how it FEELS.
//
//   make gallery
//   make gallery NAME=Button THEME=dark                      open straight onto one entry

@main
struct GalleryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = GalleryModel(arguments: CommandLine.arguments)

    var body: some Scene {
        WindowGroup("Trembus Gallery") {
            GalleryView(model: model)
        }
        .defaultSize(width: 1180, height: 780)
        .commands {
            CommandMenu("Theme") {
                ForEach(Array(ThemeMode.allCases.enumerated()), id: \.element) { index, mode in
                    Button(mode.title) { model.themeMode = mode }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }
        }
    }
}

/// `swift run` starts a bare executable, not an app bundle — without this it would launch
/// behind everything with no Dock icon and no keyboard focus.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

enum ThemeMode: String, CaseIterable, Hashable {
    case system, light, dark, reliquary

    var title: String { rawValue.capitalized }

    var choice: ThemeChoice {
        switch self {
        case .system: .automatic()
        case .light: .fixed(.light)
        case .dark: .fixed(.dark)
        case .reliquary: .fixed(.reliquary)
        }
    }

    /// `nil` follows the system; otherwise the window chrome is forced to match the theme.
    var scheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark, .reliquary: .dark
        }
    }
}

@Observable
final class GalleryModel {
    var selection: CatalogEntry.ID?
    var themeMode: ThemeMode = .system

    init(arguments: [String]) {
        selection = Catalog.entries.first?.id
        var iterator = arguments.dropFirst().makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--entry":
                if let name = iterator.next(), let entry = Catalog.entry(named: name) {
                    selection = entry.id
                }
            case "--theme":
                if let name = iterator.next(), let mode = ThemeMode(rawValue: name) { themeMode = mode }
            default: break
            }
        }
    }

    var entry: CatalogEntry? { Catalog.entries.first { $0.id == selection } }
}
