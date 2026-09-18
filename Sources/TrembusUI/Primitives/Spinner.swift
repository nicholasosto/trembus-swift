import SwiftUI

/// The web's border spinner: three quarters of a ring, one turn every 0.6 s. Drawn in the current
/// foreground style, so it takes the ink of whatever it sits in — a button label, a status line.
/// Under Reduce Motion it makes one quick turn and rests (the web clamps it to one turn too), so
/// never let it be the only signal: pair it with a word.
struct Spinner: View {
    @State private var isSpinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(.foreground, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .motion(.linear(duration: 0.6).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
            .accessibilityHidden(true)
    }
}
