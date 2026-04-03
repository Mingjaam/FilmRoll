import SwiftUI

struct RollDetailView: View {
    let roll: Roll
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
    ]

    var body: some View {
        ZStack {
            Color(hex: "#111111").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(hex: "#C8762A"))
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("ROLL \(String(format: "%02d", roll.number))")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                                .tracking(3)

                            Text(roll.dateRangeLabel)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()
                        Color.clear.frame(width: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // 필름 스트립 세로 배열
                    // 4개씩 한 줄 = 실제 필름 한 행처럼
                    let sorted = roll.sortedFrames
                    let rows = sorted.chunked(into: 4)

                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowFrames in
                            filmRow(frames: rowFrames, startIndex: rowIndex * 4)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    @ViewBuilder
    private func filmRow(frames: [Frame], startIndex: Int) -> some View {
        VStack(spacing: 0) {
            // 퍼포레이션
            perforationRow

            // 프레임들
            HStack(spacing: 0) {
                ForEach(Array(frames.enumerated()), id: \.offset) { i, frame in
                    ZStack(alignment: .bottomTrailing) {
                        if let data = frame.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        } else {
                            Color(hex: "#2B1E0F")
                        }

                        Text(frame.capturedAt.stampDate)
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundColor(Color(hex: "#E8670A").opacity(0.85))
                            .padding(3)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4.0/3.0, contentMode: .fit)
                    .clipped()

                    if i < frames.count - 1 {
                        Color(hex: "#1C1209").frame(width: 3)
                    }
                }

                // 빈 슬롯 채우기 (마지막 줄이 4개 미만일 때)
                if frames.count < 4 {
                    ForEach(0..<(4 - frames.count), id: \.self) { _ in
                        Color(hex: "#1C1209")
                            .frame(maxWidth: .infinity)
                            .aspectRatio(4.0/3.0, contentMode: .fit)
                    }
                }
            }
            .background(Color(hex: "#1C1209"))

            // 프레임 번호
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    Text(String(format: "%03d", startIndex + i + 1))
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 14)
            .background(Color(hex: "#1C1209"))

            // 퍼포레이션
            perforationRow
        }
    }

    private var perforationRow: some View {
        GeometryReader { geo in
            HStack(spacing: 7) {
                ForEach(0..<Int(geo.size.width / 21), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#0D0906"))
                        .frame(width: 14, height: 9)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 22)
        .background(Color(hex: "#1C1209"))
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
