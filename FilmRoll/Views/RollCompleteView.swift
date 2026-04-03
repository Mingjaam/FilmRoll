import SwiftUI
import AudioToolbox

struct RollCompleteView: View {
    let rollNumber: Int
    let filmName: String
    let frameCount: Int
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var canisterScale: CGFloat = 0.3
    @State private var titleOffset: CGFloat = 30
    @State private var rewindRotation: Double = 0
    @State private var rewindOpacity: Double = 1

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // 캐니스터 아이콘 (되감기 때 회전)
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
                .rotationEffect(.degrees(rewindRotation))
                .scaleEffect(canisterScale)

                VStack(spacing: 8) {
                    Text("ROLL \(String(format: "%02d", rollNumber))  ·  \(filmName.uppercased())")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                        .tracking(3)

                    Text("COMPLETE")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundColor(.white)

                    Text("\(frameCount) frames developed")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                .offset(y: titleOffset)

                Button(action: onDismiss) {
                    Text("LOAD NEW FILM")
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
            // 되감기 페이즈 먼저 실행
            Task { await playRewindSequence() }
        }
    }

    // MARK: - Rewind Animation Sequence

    private func playRewindSequence() async {
        // 캐니스터 즉시 표시
        withAnimation(.easeOut(duration: 0.15)) { opacity = 1; canisterScale = 0.9 }

        // 되감기 시작: 빠르게 회전
        withAnimation(.linear(duration: 1.0)) {
            rewindRotation = 900  // 2.5바퀴
        }

        // 연속 진동으로 필름 되감기 느낌
        let light = UIImpactFeedbackGenerator(style: .light)
        let rigid = UIImpactFeedbackGenerator(style: .rigid)
        light.prepare()
        rigid.prepare()

        for i in 0..<18 {
            try? await Task.sleep(for: .milliseconds(35 + Int64(i) * 5))
            if i % 5 == 0 {
                rigid.impactOccurred(intensity: 0.6)
            } else {
                light.impactOccurred(intensity: 0.5)
            }
        }

        // 되감기 완료 후 정착 애니메이션
        try? await Task.sleep(for: .milliseconds(200))

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            canisterScale = 1
        }
        withAnimation(.easeOut(duration: 0.4)) { titleOffset = 0 }

        // 완료 햅틱
        try? await Task.sleep(for: .milliseconds(300))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
