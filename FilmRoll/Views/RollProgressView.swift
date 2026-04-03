import SwiftUI

struct RollProgressView: View {
    let frameCount: Int
    let total: Int

    var body: some View {
        VStack(spacing: 5) {
            // 퍼포레이션 스타일 진행 바
            GeometryReader { geo in
                HStack(spacing: 3) {
                    ForEach(0..<total, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(i < frameCount
                                  ? Color(hex: "#C8762A")
                                  : Color(hex: "#2B1E0F"))
                            .frame(height: 8)
                    }
                }
            }
            .frame(height: 8)

            Text("\(frameCount) / \(total)")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
        }
        .padding(.horizontal, 32)
    }
}
