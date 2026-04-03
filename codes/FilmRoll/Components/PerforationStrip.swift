import SwiftUI

struct PerforationStrip: View {
    let width: CGFloat

    private let holeWidth: CGFloat = 14
    private let holeHeight: CGFloat = 10
    private let spacing: CGFloat = 8
    private let stripHeight: CGFloat = 26

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color(hex: "#1C1209"))
                .frame(height: stripHeight)

            // 구멍들
            GeometryReader { geo in
                let totalSlot = holeWidth + spacing
                let count = Int(geo.size.width / totalSlot) + 2

                HStack(spacing: spacing) {
                    ForEach(0..<count, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#0D0906"))
                            .frame(width: holeWidth, height: holeHeight)
                    }
                }
                .frame(maxHeight: .infinity)
                .offset(x: 6)
            }
        }
        .frame(width: width, height: stripHeight)
        .clipped()
    }
}
