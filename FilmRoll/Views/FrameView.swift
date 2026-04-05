import SwiftUI

struct FrameView: View {
    let frame: Frame?
    let index: Int
    let isCurrent: Bool
    var filmStock: FilmStock? = nil
    var allowFlip: Bool = false

    @State private var isFlipped = false
    @State private var memoText: String = ""
    @FocusState private var isMemoFocused: Bool

    private let aspectRatio: CGFloat = 4.0 / 3.0

    var body: some View {
        ZStack {
            // 앞면 (사진)
            frontSide
                .opacity(isFlipped ? 0 : 1)

            // 뒷면 (메모)
            backSide
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 1))
        .onTapGesture {
            guard allowFlip, frame?.imageData != nil else { return }
            if isFlipped {
                // 뒷면 → 앞면: 메모 저장
                saveMemo()
                isMemoFocused = false
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
            if isFlipped {
                memoText = frame?.memo ?? ""
            }
        }
        .onAppear {
            memoText = frame?.memo ?? ""
        }
    }

    // MARK: - Front Side

    private var frontSide: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                if let frame, let data = frame.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .overlay(vignetteOverlay)
                        .overlay(FilmGrainView().opacity(filmStock?.grainOpacity ?? 1.0))
                } else {
                    Rectangle()
                        .fill(Color(hex: "#2B1E0F"))
                        .overlay(FilmGrainView().opacity(0.5))
                }

                if let frame, frame.imageData != nil {
                    HStack(alignment: .bottom) {
                        if let stock = filmStock {
                            Text(stock.name.uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#E8670A"))
                                .opacity(0.85)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(frame.capturedAt.stampDate)
                            Text(frame.capturedAt.stampTime)
                        }
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#E8670A"))
                        .opacity(0.85)
                    }
                    .padding(.bottom, 6)
                    .padding(.horizontal, 8)
                }

                // 메모가 있으면 작은 표시
                if let frame, !frame.memo.isEmpty, allowFlip {
                    VStack {
                        HStack {
                            Image(systemName: "note.text")
                                .font(.system(size: 8))
                                .foregroundColor(Color(hex: "#E8670A").opacity(0.6))
                                .padding(4)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Back Side (메모)

    private var backSide: some View {
        GeometryReader { geo in
            ZStack {
                // 필름 뒷면 질감
                Color(hex: "#1A1005")

                // 미세한 텍스처 패턴
                VStack(spacing: 4) {
                    ForEach(0..<Int(geo.size.height / 6), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.015))
                            .frame(height: 0.5)
                    }
                }

                VStack(spacing: 0) {
                    // 상단: 프레임 번호 + 날짜
                    HStack {
                        Text(String(format: "%03d", index + 1))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                        Spacer()
                        if let frame {
                            Text(frame.capturedAt.stampDate)
                                .font(.system(size: 7, design: .monospaced))
                                .foregroundColor(Color(hex: "#C8762A").opacity(0.35))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

                    // MEMO 라벨
                    HStack {
                        Text("MEMO")
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.3))
                            .tracking(2)
                        Spacer()
                        Text("\(memoText.count)/50")
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundColor(.white.opacity(0.15))
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

                    // 메모 입력
                    TextField("tap to write...", text: $memoText, axis: .vertical)
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(3...5)
                        .focused($isMemoFocused)
                        .onChange(of: memoText) { _, new in
                            if new.count > 50 { memoText = String(new.prefix(50)) }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 6)

                    Spacer()

                    // 하단: 필름 이름
                    HStack {
                        if let stock = filmStock {
                            Text(stock.name.uppercased())
                                .font(.system(size: 7, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#C8762A").opacity(0.25))
                                .tracking(1)
                        }
                        Spacer()
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.3))
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }
            }
        }
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

    private func saveMemo() {
        frame?.memo = memoText
    }
}
