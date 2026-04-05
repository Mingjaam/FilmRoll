import SwiftUI

struct FilmPickerView: View {
    let onSelect: (FilmStock, Int) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStock: FilmStock?
    @State private var selectedFrameCount: Int?

    var body: some View {
        ZStack {
            Color(hex: "#0D0906").ignoresSafeArea()

            if selectedStock == nil {
                filmStockSelection
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            } else if selectedFrameCount == nil {
                frameCountSelection
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            } else {
                loadingScreen
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedStock?.id)
        .animation(.easeInOut(duration: 0.25), value: selectedFrameCount)
    }

    // MARK: - Step 1: Film Stock Selection

    private var filmStockSelection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("CHOOSE FILM")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                    .tracking(4)

                Text("오늘의 필름")
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(.white.opacity(0.9))

                Text("어떤 감도로 세상을 담을까요")
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.top, 56)
            .padding(.bottom, 32)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(FilmStock.all) { stock in
                        FilmStockCard(stock: stock) {
                            selectedStock = stock
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Step 2: Frame Count Selection

    private var frameCountSelection: some View {
        VStack(spacing: 0) {
            // 뒤로 + 선택된 필름명
            HStack {
                Button(action: { selectedStock = nil }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .medium))
                        Text("필름 선택")
                            .font(.system(size: 11, design: .monospaced))
                    }
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)

            if let stock = selectedStock {
                // 필름 시각화
                VStack(spacing: 20) {
                    // 캐니스터 일러스트
                    ZStack {
                        // 그림자 글로우
                        Ellipse()
                            .fill(stock.dimmedCanisterColor.opacity(0.15))
                            .frame(width: 80, height: 20)
                            .offset(y: 58)
                            .blur(radius: 8)

                        // 캐니스터 몸통
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(stock.dimmedCanisterColor)
                                .frame(width: 68, height: 88)

                            // 하이라이트
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 68, height: 88)

                            VStack(spacing: 6) {
                                // 퍼포레이션
                                HStack(spacing: 4) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .fill(Color.black.opacity(0.2))
                                            .frame(width: 8, height: 5)
                                    }
                                }

                                Text(stock.name.uppercased())
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black.opacity(0.45))
                                    .tracking(1)

                                Text("ISO")
                                    .font(.system(size: 5, design: .monospaced))
                                    .foregroundColor(.black.opacity(0.3))
                            }
                            .offset(y: 4)

                            // 상단 캡
                            RoundedRectangle(cornerRadius: 4)
                                .fill(stock.dimmedCanisterColor)
                                .brightness(0.2)
                                .frame(width: 32, height: 10)
                                .offset(y: -44)
                        }
                    }
                    .padding(.top, 24)

                    VStack(spacing: 4) {
                        Text(stock.name)
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(.white.opacity(0.9))

                        Text(stock.tagline)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 36)

                // 구분선
                HStack {
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                    Text("EXPOSURES")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white.opacity(0.2))
                        .tracking(2)
                        .padding(.horizontal, 12)
                        .fixedSize()
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // 장수 선택 그리드
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(FilmStock.availableFrameCounts, id: \.self) { count in
                        FrameCountCard(count: count, stock: stock) {
                            selectedFrameCount = count
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                onSelect(stock, count)
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }

    // MARK: - Step 3: Loading

    private var loadingScreen: some View {
        VStack(spacing: 24) {
            if let stock = selectedStock, let count = selectedFrameCount {
                ZStack {
                    Ellipse()
                        .fill(stock.dimmedCanisterColor.opacity(0.2))
                        .frame(width: 100, height: 24)
                        .offset(y: 56)
                        .blur(radius: 10)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(stock.dimmedCanisterColor)
                            .frame(width: 80, height: 100)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 100)

                        VStack(spacing: 8) {
                            Text(stock.name.uppercased())
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.black.opacity(0.4))
                                .tracking(1)
                            Text("\(count)")
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.black.opacity(0.65))
                            Text("EXP")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(.black.opacity(0.35))
                        }

                        // 상단 캡
                        RoundedRectangle(cornerRadius: 5)
                            .fill(stock.dimmedCanisterColor)
                            .brightness(0.2)
                            .frame(width: 36, height: 12)
                            .offset(y: -52)
                    }
                }

                VStack(spacing: 6) {
                    Text("필름 장전 중")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(Color(hex: "#C8762A").opacity(0.6))
                                .frame(width: 4, height: 4)
                                .scaleEffect(1.0)
                                .animation(
                                    .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                                    value: selectedFrameCount
                                )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Film Stock Card

struct FilmStockCard: View {
    let stock: FilmStock
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 왼쪽: 캐니스터 블록
                ZStack {
                    stock.dimmedCanisterColor

                    // 하이라이트
                    LinearGradient(
                        colors: [.white.opacity(0.15), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: 0) {
                        stock.dimmedCanisterColor.brightness(0.18).frame(height: 10)
                        Spacer()

                        VStack(spacing: 5) {
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.black.opacity(0.2))
                                        .frame(width: 8, height: 5)
                                }
                            }
                            Text(stock.name.uppercased())
                                .font(.system(size: 6, weight: .bold, design: .monospaced))
                                .foregroundColor(.black.opacity(0.4))
                                .tracking(1)
                        }

                        Spacer()
                        stock.dimmedCanisterColor.brightness(-0.12).frame(height: 8)
                    }
                }
                .frame(width: 60)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // 오른쪽: 필름 정보
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(stock.name)
                            .font(.system(size: 19, weight: .light))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Circle()
                            .fill(stock.dimmedCanisterColor)
                            .frame(width: 8, height: 8)
                    }
                    Text(stock.tagline)
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(height: 70)
        .background(Color(hex: "#150D04"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(stock.dimmedCanisterColor.opacity(0.12), lineWidth: 1)
        )
        .buttonStyle(FilmCardButtonStyle())
    }
}

// MARK: - Frame Count Card (그리드형, 감성적)

struct FrameCountCard: View {
    let count: Int
    let stock: FilmStock
    let onTap: () -> Void

    private var label: String {
        switch count {
        case 1:  return "한 장의 기억"
        case 12: return "짧은 여행"
        case 24: return "하루의 기록"
        case 36: return "온전한 롤"
        default: return "\(count) 장"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 36, weight: .light, design: .monospaced))
                        .foregroundColor(stock.dimmedCanisterColor)

                    Text("EXP")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(stock.dimmedCanisterColor.opacity(0.5))
                        .offset(y: -6)
                }

                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))

                // 필름 스트립 시각화
                HStack(spacing: 3) {
                    ForEach(0..<min(count, 8), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(stock.dimmedCanisterColor.opacity(0.25))
                            .frame(width: 6, height: 8)
                    }
                    if count > 8 {
                        Text("···")
                            .font(.system(size: 8))
                            .foregroundColor(stock.dimmedCanisterColor.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(stock.dimmedCanisterColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(stock.dimmedCanisterColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(FrameCountButtonStyle())
    }
}

// MARK: - Button Styles

private struct FilmCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct FrameCountButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
