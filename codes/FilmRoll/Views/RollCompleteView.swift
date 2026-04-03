import SwiftUI

struct RollCompleteView: View {
    let rollNumber: Int
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var canisterScale: CGFloat = 0.3
    @State private var titleOffset: CGFloat = 30

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // 캐니스터 아이콘
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#C8762A"))
                        .frame(width: 64, height: 80)

                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "#1C1209"))
                            .frame(width: 20, height: 20)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#1C1209").opacity(0.5))
                            .frame(width: 40, height: 6)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#1C1209").opacity(0.5))
                            .frame(width: 40, height: 6)
                    }
                }
                .scaleEffect(canisterScale)

                VStack(spacing: 8) {
                    Text("ROLL \(String(format: "%02d", rollNumber))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                        .tracking(4)

                    Text("COMPLETE")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundColor(.white)

                    Text("36 frames developed")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                .offset(y: titleOffset)

                Button(action: onDismiss) {
                    Text("START NEW ROLL")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Color(hex: "#1C1209"))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#C8762A"))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .offset(y: titleOffset)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                opacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                canisterScale = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                titleOffset = 0
            }
        }
    }
}
