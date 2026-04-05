import SwiftUI

struct RollCompleteView: View {
    let rollNumber: Int
    let filmName: String
    let frameCount: Int
    let filmStock: FilmStock
    let onDismiss: () -> Void
    let onGoHome: () -> Void

    @State private var opacity: Double = 0
    @State private var canisterScale: CGFloat = 0.7
    @State private var titleOffset: CGFloat = 24

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // 캐니스터
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(filmStock.dimmedCanisterColor)
                        .frame(width: 64, height: 80)

                    // 하이라이트
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.18), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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

                    // 상단 캡
                    RoundedRectangle(cornerRadius: 4)
                        .fill(filmStock.dimmedCanisterColor)
                        .brightness(0.15)
                        .frame(width: 30, height: 10)
                        .offset(y: -42)
                }
                .scaleEffect(canisterScale)
                .shadow(color: filmStock.dimmedCanisterColor.opacity(0.4), radius: 20, x: 0, y: 8)

                VStack(spacing: 8) {
                    Text("ROLL \(String(format: "%02d", rollNumber))  ·  \(filmName.uppercased())")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                        .tracking(3)

                    Text("COMPLETE")
                        .font(.system(size: 28, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(4)

                    Text("\(frameCount) frames developed")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                }
                .offset(y: titleOffset)

                VStack(spacing: 10) {
                    Button(action: onDismiss) {
                        Text("LOAD NEW FILM")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(Color(hex: "#1C1209"))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#C8762A"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Button(action: onGoHome) {
                        Text("GO TO HOME")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 32)
                .offset(y: titleOffset)
            }
        }
        .opacity(opacity)
        .onAppear {
            Task { await playAppearSequence() }
        }
    }

    private func playAppearSequence() async {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            opacity = 1
            canisterScale = 1
        }
        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.easeOut(duration: 0.35)) {
            titleOffset = 0
        }
        try? await Task.sleep(for: .milliseconds(300))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
