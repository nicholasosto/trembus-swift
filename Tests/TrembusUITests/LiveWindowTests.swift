import AppKit
import SwiftUI
import Testing

/// The parent of every suite that mounts a real (never shown) window.
///
/// Each of those windows CLAIMS to be key — a test runner's window can never really be — and an app has
/// one focus. Two such windows alive at once steal it from each other: a click or a Tab in one lands
/// nowhere in the other. `.serialized` reaches into nested suites, so everything under here runs one
/// test at a time, across files. Put a new live suite in an `extension LiveWindowTests { … }`.
@Suite("Live windows", .serialized)
enum LiveWindowTests {
    /// SwiftUI only mirrors AppKit focus into `@FocusState` for a KEY window. A test runner's window can
    /// never really be key, so this one just says it is.
    final class AlwaysKeyWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var isKeyWindow: Bool { true }
    }

    /// An `NSHostingView` refuses the first click of an INACTIVE app — and a test runner is never active.
    /// Without this (and an ordered-in window) a synthesized click never reaches a SwiftUI gesture.
    final class ClickableHost<Content: View>: NSHostingView<Content> {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }

    static func settle(_ seconds: TimeInterval = 0.25) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    static func mount<Content: View>(_ view: Content) -> (NSWindow, NSHostingView<Content>) {
        _ = NSApplication.shared
        let host = ClickableHost(rootView: view)
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        // Parked far off-screen and ordered in: it never shows, never activates the app, never takes
        // the user's focus — but events only reach a window that is ordered in.
        let window = AlwaysKeyWindow(
            contentRect: NSRect(origin: NSPoint(x: -6000, y: -6000), size: host.frame.size),
            styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFrontRegardless()
        host.layoutSubtreeIfNeeded()
        settle()
        return (window, host)
    }

    static func unmount(_ window: NSWindow) {
        window.orderOut(nil)
        window.contentView = nil
    }

    static func find<V: NSView>(_ type: V.Type, in view: NSView) -> V? {
        if let found = view as? V { return found }
        for sub in view.subviews { if let found = find(type, in: sub) { return found } }
        return nil
    }

    /// A real click, delivered the way the window server would.
    static func click(_ window: NSWindow, at point: NSPoint) {
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            if let event = NSEvent.mouseEvent(
                with: type, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
            {
                window.sendEvent(event)
            }
        }
    }

    /// A real key press, delivered the way the window server would.
    static func press(_ window: NSWindow, _ characters: String, keyCode: UInt16, shift: Bool = false) {
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            if let event = NSEvent.keyEvent(
                with: type, location: .zero, modifierFlags: shift ? [.shift] : [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil,
                characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: keyCode)
            {
                window.sendEvent(event)
            }
        }
    }
}
