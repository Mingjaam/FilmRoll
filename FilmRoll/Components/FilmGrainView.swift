import SwiftUI

struct FilmGrainView: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { ctx, size in
                let grainCount = 600
                for _ in 0..<grainCount {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let radius = CGFloat.random(in: 0.3...1.1)
                    let opacity = Double.random(in: 0.02...0.09)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
