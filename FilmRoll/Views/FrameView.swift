import SwiftUI

struct FrameView: View {
    let frame: Frame?
    let index: Int
    let isCurrent: Bool
    var filmStock: FilmStock? = nil

    private let aspectRatio: CGFloat = 4.0 / 3.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                // 프레임 배경
                if let frame, let data = frame.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .applyFilmGrading(filmStock)
                        .overlay(vignetteOverlay)
                        .overlay(FilmGrainView().opacity(filmStock?.grainOpacity ?? 1.0))
                } else {
                    // 빈 프레임
                    Rectangle()
                        .fill(Color(hex: "#2B1E0F"))
                        .overlay(FilmGrainView().opacity(0.5))
                }

                // 날짜 스탬프 (사진이 있을 때만)
                if let frame, frame.imageData != nil {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(frame.capturedAt.stampDate)
                        Text(frame.capturedAt.stampTime)
                    }
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(hex: "#E8670A"))
                    .opacity(0.85)
                    .padding(.bottom, 6)
                    .padding(.trailing, 8)
                }
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 1))
    }

    private var vignetteOverlay: some View {
        let opacity = filmStock?.vignetteOpacity ?? 0.35
        return RadialGradient(
            gradient: Gradient(colors: [
                .clear,
                .clear,
                Color.black.opacity(opacity)
            ]),
            center: .center,
            startRadius: 60,
            endRadius: 160
        )
    }
}
