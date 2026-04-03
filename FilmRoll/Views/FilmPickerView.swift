import SwiftUI

struct FilmPickerView: View {
    let onSelect: (FilmStock) -> Void

    var body: some View {
        ZStack {
            Color(hex: "#111111").ignoresSafeArea()

            VStack(spacing: 0) {
                // 헤더
                VStack(spacing: 8) {
                    Text("LOAD FILM")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                        .tracking(4)

                    Text("어떤 필름으로 오늘을 찍을까요")
                        .font(.system(size: 17, weight: .light))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.top, 52)
                .padding(.bottom, 32)

                // 필름 리스트
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(FilmStock.all) { stock in
                            FilmStockCard(stock: stock) {
                                onSelect(stock)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
                }
            }
        }
    }
}

// MARK: - Film Stock Card

struct FilmStockCard: View {
    let stock: FilmStock
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {

                // 왼쪽: 캐니스터 블록
                ZStack {
                    Color(hex: stock.canisterHex)

                    VStack(spacing: 0) {
                        // 캡
                        Color(hex: stock.canisterHex)
                            .brightness(0.15)
                            .frame(height: 10)

                        Spacer()

                        // 퍼포레이션 + 이름 라벨
                        VStack(spacing: 5) {
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.black.opacity(0.25))
                                        .frame(width: 8, height: 5)
                                }
                            }

                            Text(stock.name.uppercased())
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.black.opacity(0.45))
                                .tracking(1)
                        }

                        Spacer()

                        // 하단 캡
                        Color(hex: stock.canisterHex)
                            .brightness(-0.1)
                            .frame(height: 8)
                    }
                }
                .frame(width: 64)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // 오른쪽: 필름 정보
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(stock.name)
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white)

                        Spacer()

                        // 장수 뱃지
                        Text("\(stock.frameCount) EXP")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: stock.canisterHex))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(hex: stock.canisterHex).opacity(0.15))
                            )
                    }

                    Text(stock.tagline)
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
        }
        .frame(height: 74)
        .background(Color(hex: "#1C1408"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
