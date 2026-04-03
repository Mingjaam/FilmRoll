import SwiftUI

struct RollDetailView: View {
    let roll: Roll
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFrame: Frame? = nil
    @State private var showShareSheet = false
    @State private var exportImage: UIImage? = nil

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
                            Text("ROLL \(String(format: "%02d", roll.number))  ·  \(roll.filmStock.name.uppercased())")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                                .tracking(2)

                            Text(roll.dateRangeLabel)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        // 내보내기 버튼
                        Button(action: exportRoll) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#C8762A").opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // 필름 스트립 세로 배열 (4열)
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
        .sheet(item: $selectedFrame) { frame in
            FrameDetailView(frame: frame, filmStock: roll.filmStock)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = exportImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Export

    private func exportRoll() {
        let renderer = ImageRenderer(
            content: FilmExportView(roll: roll)
                .frame(width: 393)
                .background(Color(hex: "#111111"))
        )
        renderer.scale = 3.0
        renderer.proposedSize = .init(width: 393, height: nil)

        if let image = renderer.uiImage {
            exportImage = image
            showShareSheet = true
        }
    }

    // MARK: - Film Row

    @ViewBuilder
    private func filmRow(frames: [Frame], startIndex: Int) -> some View {
        VStack(spacing: 0) {
            perforationRow

            HStack(spacing: 0) {
                ForEach(Array(frames.enumerated()), id: \.offset) { i, frame in
                    ZStack(alignment: .bottomTrailing) {
                        if let data = frame.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .applyFilmGrading(roll.filmStock)
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
                    .onTapGesture { selectedFrame = frame }

                    if i < frames.count - 1 {
                        Color(hex: "#241810").frame(width: 3)
                    }
                }

                if frames.count < 4 {
                    ForEach(0..<(4 - frames.count), id: \.self) { _ in
                        Color(hex: "#241810")
                            .frame(maxWidth: .infinity)
                            .aspectRatio(4.0/3.0, contentMode: .fit)
                    }
                }
            }
            .background(Color(hex: "#241810"))

            // 프레임 번호 + 메모
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    VStack(spacing: 2) {
                        Text(String(format: "%03d", startIndex + i + 1))
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.5))

                        if i < frames.count && !frames[i].memo.isEmpty {
                            Text(frames[i].memo)
                                .font(.system(size: 6, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(minHeight: 16)
            .padding(.vertical, 2)
            .background(Color(hex: "#241810"))

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
        .background(Color(hex: "#241810"))
    }
}

// MARK: - Film Export View (used by ImageRenderer)

private struct FilmExportView: View {
    let roll: Roll

    var body: some View {
        let sorted = roll.sortedFrames
        let rows = sorted.chunked(into: 4)

        VStack(spacing: 0) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ROLL \(String(format: "%02d", roll.number))  ·  \(roll.filmStock.name.uppercased())")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: roll.filmStock.canisterHex))
                        .tracking(2)
                    Text(roll.dateRangeLabel)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Text("FilmRoll")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowFrames in
                exportFilmRow(frames: rowFrames, startIndex: rowIndex * 4)
            }
        }
        .background(Color(hex: "#111111"))
    }

    @ViewBuilder
    private func exportFilmRow(frames: [Frame], startIndex: Int) -> some View {
        VStack(spacing: 0) {
            exportPerforationRow

            HStack(spacing: 0) {
                ForEach(Array(frames.enumerated()), id: \.offset) { i, frame in
                    ZStack(alignment: .bottomTrailing) {
                        if let data = frame.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .applyFilmGrading(roll.filmStock)
                        } else {
                            Color(hex: "#2B1E0F")
                        }

                        Text(frame.capturedAt.stampDate)
                            .font(.system(size: 5, design: .monospaced))
                            .foregroundColor(Color(hex: "#E8670A").opacity(0.8))
                            .padding(2)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4.0/3.0, contentMode: .fit)
                    .clipped()

                    if i < frames.count - 1 {
                        Color(hex: "#241810").frame(width: 2)
                    }
                }

                ForEach(0..<max(0, 4 - frames.count), id: \.self) { _ in
                    Color(hex: "#241810")
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4.0/3.0, contentMode: .fit)
                }
            }
            .background(Color(hex: "#241810"))

            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    VStack(spacing: 1) {
                        Text(String(format: "%03d", startIndex + i + 1))
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                        if i < frames.count && !frames[i].memo.isEmpty {
                            Text(frames[i].memo)
                                .font(.system(size: 5, design: .monospaced))
                                .foregroundColor(.white.opacity(0.25))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(minHeight: 14)
            .padding(.vertical, 1)
            .background(Color(hex: "#241810"))

            exportPerforationRow
        }
    }

    // 고정 퍼포레이션 (ImageRenderer용 — GeometryReader 미사용)
    private var exportPerforationRow: some View {
        HStack(spacing: 7) {
            ForEach(0..<18, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#0D0906"))
                    .frame(width: 14, height: 9)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 22)
        .background(Color(hex: "#241810"))
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
