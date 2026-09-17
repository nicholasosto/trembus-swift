import AppKit
import SwiftUI

/// Renders any SwiftUI view to PNG, headlessly — no window ever appears.
///
/// Uses an offscreen `NSHostingView` rather than `ImageRenderer`, because `ImageRenderer`
/// can't draw AppKit-backed controls (text fields, native toggles come out as yellow
/// "🚫" placeholders). This path draws everything a real window would.
public enum Snapshotter {
    public struct Output {
        public let png: Data
        /// Size in points.
        public let size: CGSize
        public let scale: CGFloat
        /// Fraction of pixels that differ from the top-left pixel. 0 means a blank image.
        public let inkCoverage: Double
    }

    public enum Failure: Error, CustomStringConvertible {
        case emptyLayout(CGSize)
        case bitmapAllocation
        case pngEncoding

        public var description: String {
            switch self {
            case .emptyLayout(let size):
                "view laid out to \(size) — give flexible specimens a .frame(width:)"
            case .bitmapAllocation: "could not allocate the bitmap"
            case .pngEncoding: "could not encode PNG"
            }
        }
    }

    /// Longest edge a snapshot may have, in points. A view that wants more than this has an
    /// unbounded layout — almost always a missing `.frame(width:)`.
    static let maxEdge: CGFloat = 6000

    public static func png(of view: some View, scale: CGFloat = 2) throws -> Output {
        _ = NSApplication.shared  // AppKit needs an app object before it will lay out views.

        // `displayScale` — SwiftUI rounds layout to whole pixels of the display it thinks it
        // is on. Pin it, so a hairline lands the same on a 1× monitor as on a Retina one.
        let host = NSHostingView(rootView: view.environment(\.displayScale, scale))
        let size = host.fittingSize
        guard size.width >= 1, size.height >= 1, size.width <= maxEdge, size.height <= maxEdge
        else { throw Failure.emptyLayout(size) }

        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(
            contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        // One turn of the run loop lets `onAppear` state and geometry readers settle.
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        host.layoutSubtreeIfNeeded()

        defer { window.contentView = nil }
        return try capture(host, scale: scale)
    }

    private static func capture(_ view: NSView, scale: CGFloat) throws -> Output {
        let size = view.bounds.size
        guard size.width >= 1, size.height >= 1 else { throw Failure.emptyLayout(size) }

        // An offscreen window rasterizes at the MAIN SCREEN's scale. On a 1× monitor that made
        // every "2×" snapshot a blurry enlargement — and made output differ between machines.
        // Forcing the scale on the whole layer tree re-rasterizes text and shapes at true
        // density, whatever display happens to be attached.
        if let layer = view.layer {
            prepareForSoftwareRender(layer, scale: scale)
            layer.displayIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }

        guard
            let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int((size.width * scale).rounded(.up)),
                pixelsHigh: Int((size.height * scale).rounded(.up)), bitsPerSample: 8,
                samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                bytesPerRow: 0, bitsPerPixel: 0)
        else { throw Failure.bitmapAllocation }
        bitmap.size = size  // pixels ÷ points = scale
        view.cacheDisplay(in: view.bounds, to: bitmap)

        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw Failure.pngEncoding
        }
        return Output(png: png, size: size, scale: scale, inkCoverage: inkCoverage(of: bitmap))
    }

    /// A continuous ("squircle") corner needs this many radii of straight edge to blend in.
    private static let continuousCornerReach: CGFloat = 1.528

    /// `cacheDisplay` draws with Core Animation's SOFTWARE renderer, which differs from the
    /// GPU renderer a real window uses in two ways that matter. Both are corrected here, on
    /// the capture copy only — components are never bent to suit the camera.
    private static func prepareForSoftwareRender(_ layer: CALayer, scale: CGFloat) {
        // 1 · Density (see above): rasterize at the requested scale, not the screen's.
        layer.contentsScale = scale
        layer.rasterizationScale = scale
        layer.setNeedsDisplay()

        // 2 · Pills: SwiftUI draws `Capsule()` as a layer with a CONTINUOUS corner curve. When
        //     the radius leaves no room for that curve to blend (any full pill), the GPU
        //     quietly falls back to a circular arc; the software renderer instead draws stray
        //     ticks at both ends. Make the same fallback explicit so the photo matches the screen.
        if layer.cornerCurve == .continuous, layer.cornerRadius > 0 {
            let shortSide = min(layer.bounds.width, layer.bounds.height)
            if layer.cornerRadius * 2 * continuousCornerReach > shortSide {
                layer.cornerCurve = .circular
            }
        }
        layer.sublayers?.forEach { prepareForSoftwareRender($0, scale: scale) }
    }

    /// Samples a grid of pixels and reports how many differ from the first one.
    private static func inkCoverage(of bitmap: NSBitmapImageRep) -> Double {
        guard let data = bitmap.bitmapData else { return 0 }
        let bytesPerPixel = bitmap.bitsPerPixel / 8
        let stride = max(1, min(bitmap.pixelsWide, bitmap.pixelsHigh) / 64)
        var total = 0
        var different = 0
        for y in Swift.stride(from: 0, to: bitmap.pixelsHigh, by: stride) {
            for x in Swift.stride(from: 0, to: bitmap.pixelsWide, by: stride) {
                let offset = y * bitmap.bytesPerRow + x * bytesPerPixel
                total += 1
                for channel in 0..<bytesPerPixel where data[offset + channel] != data[channel] {
                    different += 1
                    break
                }
            }
        }
        return total == 0 ? 0 : Double(different) / Double(total)
    }
}
