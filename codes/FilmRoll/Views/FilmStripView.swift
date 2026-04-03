import SwiftUI

struct FilmStripView: View {
    let roll: Roll
    let currentIndex: Int
    let onFrameTap: (Int) -> Void

    // 프레임 하나의 너비 (화면의 약 78%)
    private let frameWidthRatio: CGFloat = 0.78
    private let frameSpacing: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let frameWidth = geo.size.width * frameWidthRatio
            let frameHeight = frameWidth * (3.0 / 4.0)
            let totalHeight = frameHeight + 52 // 퍼포레이션 포함

            VStack(spacing: 0) {
                // 상단 퍼포레이션
                PerforationStrip(width: geo.size.width)

                // 필름 베이스 + 프레임들
                ZStack(alignment: .leading) {
                    Color(hex: "#1C1209")
                        .frame(height: frameHeight)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: frameSpacing) {
                            // 앞 패딩 — 첫 프레임이 중앙에 오도록
                            Spacer()
                                .frame(width: (geo.size.width - frameWidth) / 2)

                            ForEach(Array(displayFrames(frameWidth: frameWidth).enumerated()), id: \.offset) { i, item in
                                FrameView(
                                    frame: item.frame,
                                    index: i,
                                    isCurrent: i == currentIndex
                                )
                                .frame(width: frameWidth, height: frameHeight)
                                .id(i)
                                .onTapGesture { onFrameTap(i) }
                            }

                            // 뒤 패딩
                            Spacer()
                                .frame(width: (geo.size.width - frameWidth) / 2)
                        }
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollTargetLayout()
                    .frame(height: frameHeight)
                }
                .frame(height: frameHeight)

                // 하단 퍼포레이션
                PerforationStrip(width: geo.size.width)
            }
            .frame(height: totalHeight)
        }
    }

    // 찍힌 프레임 + 현재 빈 프레임 + 다음 빈 프레임 1개
    private func displayFrames(frameWidth: CGFloat) -> [(frame: Frame?, index: Int)] {
        let sorted = roll.sortedFrames
        var items: [(Frame?, Int)] = sorted.enumerated().map { ($0.element, $0.offset) }

        if !roll.isComplete {
            items.append((nil, sorted.count))       // 현재 빈 프레임
            items.append((nil, sorted.count + 1))   // 다음 빈 프레임
        }
        return items
    }
}
