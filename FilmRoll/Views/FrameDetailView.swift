import SwiftUI

struct FrameDetailView: View {
    let frame: Frame
    let filmStock: FilmStock?

    @Environment(\.dismiss) private var dismiss
    @State private var memoText: String

    init(frame: Frame, filmStock: FilmStock? = nil) {
        self.frame = frame
        self.filmStock = filmStock
        _memoText = State(initialValue: frame.memo)
    }

    var body: some View {
        ZStack {
            Color(hex: "#111111").ignoresSafeArea()

            VStack(spacing: 0) {
                // 헤더
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(frame.capturedAt.stampDate)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                        Text(frame.capturedAt.stampTime)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                    }

                    Spacer()

                    Button("DONE") {
                        saveMemo()
                        dismiss()
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A"))
                    .tracking(1)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)

                // 프레임 이미지
                if let data = frame.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .applyFilmGrading(filmStock)
                        .overlay(vignetteOverlay)
                        .padding(.horizontal, 16)
                } else {
                    Color(hex: "#2B1E0F")
                        .aspectRatio(4.0/3.0, contentMode: .fit)
                        .padding(.horizontal, 16)
                }

                // 메모 영역
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("MEMO")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                            .tracking(3)
                        Spacer()
                        Text("\(memoText.count)/50")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.2))
                    }

                    TextField("이 순간을 기록하세요...", text: $memoText, axis: .vertical)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(3...4)
                        .onChange(of: memoText) { _, new in
                            if new.count > 50 { memoText = String(new.prefix(50)) }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()
            }
        }
        .onDisappear { saveMemo() }
    }

    private func saveMemo() {
        frame.memo = memoText
    }

    private var vignetteOverlay: some View {
        let opacity = filmStock?.vignetteOpacity ?? 0.1
        return RadialGradient(
            gradient: Gradient(colors: [.clear, .clear, Color.black.opacity(opacity * 2)]),
            center: .center,
            startRadius: 80,
            endRadius: 220
        )
    }
}
