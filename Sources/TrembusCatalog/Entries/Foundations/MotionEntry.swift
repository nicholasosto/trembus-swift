import SwiftUI
import TrembusTokens
import TrembusUI

extension CatalogEntry {
    static let motion = CatalogEntry(
        name: "Motion",
        kind: .foundation,
        summary: "Curves for color and layout (shared with the web). Springs for anything the pointer touches.",
        specimens: [
            Specimen("Curves", note: "Motion.calm(.base) · Motion.exit(.fast) — progress over time") {
                HStack(spacing: Space.s6) {
                    CurvePlot(title: "easeCalm", caption: "settles gently") { Motion.easeCalm.value(at: $0) }
                    CurvePlot(title: "easeExit", caption: "accelerates away") { Motion.easeExit.value(at: $0) }
                    VStack(alignment: .leading, spacing: Space.s3) {
                        ForEach(Motion.Duration.allCases, id: \.self) { duration in
                            MatrixRow(duration.rawValue) {
                                Text("\(Int(duration.seconds * 1000)) ms")
                                    .font(.trembus(.sm, family: .mono))
                                    .foregroundStyle(.theme(.text))
                            }
                        }
                    }
                }
            },
            Specimen("Springs", note: "Motion.spring(.snap) — position over 0.6 s; the dashed line is the target") {
                HStack(spacing: Space.s6) {
                    ForEach(Motion.Springs.allCases, id: \.self) { spring in
                        CurvePlot(title: spring.rawValue, caption: spring.job, target: 1, headroom: 0.25) {
                            spring.spring.value(target: 1.0, initialVelocity: 0, time: $0 * 0.6)
                        }
                    }
                }
            },
            Specimen("Race", note: "live — press Replay in the gallery to race them") {
                MotionRace()
            },
        ])
}

extension Motion.Springs {
    fileprivate var job: String {
        switch self {
        case .press: "going down"
        case .release: "coming back up"
        case .snap: "thumb finds home"
        case .settle: "panels arriving"
        }
    }
}

/// Plots y = f(x) for x in 0...1 inside a sunken well.
private struct CurvePlot: View {
    let title: String
    let caption: String
    var target: Double?
    var headroom: Double = 0
    let function: (Double) -> Double

    private let side: CGFloat = 120

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.md.value, style: .continuous)
        VStack(alignment: .leading, spacing: Space.s2) {
            ZStack {
                shape.fill(.theme(.surfaceSunken))
                if let target {
                    Path { path in
                        path.move(to: point(0, target))
                        path.addLine(to: point(1, target))
                    }
                    .stroke(.theme(.borderStrong), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                Path { path in
                    let samples = 96
                    for index in 0...samples {
                        let x = Double(index) / Double(samples)
                        let next = point(x, function(x))
                        if index == 0 { path.move(to: next) } else { path.addLine(to: next) }
                    }
                }
                .stroke(.tone(.accent), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(width: side, height: side)
            .overlay(shape.strokeBorder(.theme(.border), lineWidth: 1))
            Text(title).font(.trembus(.xs, weight: .medium)).foregroundStyle(.theme(.text))
            Text(caption).font(.trembus(.xs)).foregroundStyle(.theme(.textFaint))
        }
    }

    /// Maps the unit square (y up) into the well, leaving `headroom` above 1 for overshoot.
    private func point(_ x: Double, _ y: Double) -> CGPoint {
        let inset: CGFloat = 12
        let span = side - inset * 2
        return CGPoint(x: inset + span * x, y: inset + span * (1 - y / (1 + headroom)))
    }
}

/// Every motion token moving the same distance at once — feel the difference.
private struct MotionRace: View {
    @State private var isAtEnd = false

    private let lanes: [(String, Animation)] =
        [("calm", Motion.calm(.slow)), ("exit", Motion.exit(.slow))]
        + Motion.Springs.allCases.map { ($0.rawValue, Motion.spring($0)) }
    private let travel: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            ForEach(lanes, id: \.0) { name, animation in
                MatrixRow(name) {
                    Capsule()
                        .fill(.theme(.surfaceSunken))
                        .frame(width: travel + 14, height: 14)
                        .overlay(alignment: .leading) {
                            Circle()
                                .fill(.tone(.accent))
                                .frame(width: 14, height: 14)
                                .offset(x: isAtEnd ? travel : 0)
                                .animation(animation, value: isAtEnd)
                        }
                }
            }
            Button("Replay") { isAtEnd.toggle() }
                .buttonStyle(.trembus(.outline))
                .controlSize(.small)
                .padding(.top, Space.s2)
        }
    }
}

struct MotionEntry_Previews: PreviewProvider {
    static var previews: some View { EntrySheet(.motion) }
}
