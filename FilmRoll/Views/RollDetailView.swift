import SwiftUI
import Photos

// MARK: - Async Frame Image

private struct AsyncFrameImage: View {
    let data: Data?
    let filmStock: FilmStock

    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color(hex: "#2B1E0F")
            }
        }
        .task(id: data) {
            guard let data else { return }
            let decoded = await Task.detached(priority: .userInitiated) {
                UIImage(data: data)
            }.value
            image = decoded
        }
    }
}

// MARK: - RollDetailView

struct RollDetailView: View {
    let roll: Roll
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var selectedFrame: Frame? = nil
    @State private var isSelecting = false
    @State private var selectedFrames: Set<UUID> = []
    @State private var showSaveSheet = false
    @State private var showDeleteConfirm = false

    // 3열 그리드
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        ZStack {
            Color(hex: "#111111").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header

                    let sorted = roll.sortedFrames
                    let rows = sorted.chunked(into: 3)

                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowFrames in
                            filmRow(frames: rowFrames, startIndex: rowIndex * 3)
                        }
                    }
                    .padding(.bottom, isSelecting ? 100 : 40)
                }
            }

            // 하단 저장 바
            if isSelecting && !selectedFrames.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Text("\(selectedFrames.count)장 선택됨")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))

                        Spacer()

                        Button(action: { showDeleteConfirm = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                Text("DELETE")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .tracking(1)
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.4), lineWidth: 1))
                        }

                        Button(action: { showSaveSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 13))
                                Text("SAVE")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .tracking(1)
                            }
                            .foregroundColor(Color(hex: "#1C1209"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#C8762A"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Color(hex: "#0D0906")
                            .overlay(Rectangle().fill(Color(hex: "#C8762A").opacity(0.15)).frame(height: 1), alignment: .top)
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $selectedFrame) { frame in
            FrameDetailView(frame: frame, filmStock: roll.filmStock)
        }
        .alert("선택한 사진을 삭제할까요?", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) { }
            Button("\(selectedFrames.count)장 삭제", role: .destructive) {
                let framesToDelete = roll.frames.filter { selectedFrames.contains($0.id) }
                for frame in framesToDelete {
                    context.delete(frame)
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedFrames = []
                    isSelecting = false
                }
            }
        } message: {
            Text("삭제된 사진은 복구할 수 없어요.")
        }
        .sheet(isPresented: $showSaveSheet) {
            let frames = roll.sortedFrames.filter { selectedFrames.contains($0.id) }
            SaveOptionsSheet(frames: frames, roll: roll) {
                showSaveSheet = false
                isSelecting = false
                selectedFrames = []
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                if isSelecting {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSelecting = false
                        selectedFrames = []
                    }
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: isSelecting ? "xmark" : "chevron.left")
                    .foregroundColor(Color(hex: "#C8762A"))
                    .font(.system(size: 15, weight: .medium))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("ROLL \(String(format: "%02d", roll.number))  ·  \(roll.filmStock.name.uppercased())")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                    .tracking(2)
                Text(roll.dateRangeLabel)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSelecting.toggle()
                    if !isSelecting { selectedFrames = [] }
                }
            }) {
                Image(systemName: isSelecting ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Film Row (3열)

    @ViewBuilder
    private func filmRow(frames: [Frame], startIndex: Int) -> some View {
        VStack(spacing: 0) {
            perforationRow(frameCount: 3)

            HStack(spacing: 0) {
                ForEach(Array(frames.enumerated()), id: \.offset) { i, frame in
                    ZStack(alignment: .bottomTrailing) {
                        AsyncFrameImage(data: frame.imageData, filmStock: roll.filmStock)

                        // 날짜 스탬프
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(frame.capturedAt.stampDate)
                                .font(.system(size: 7, weight: .regular, design: .monospaced))
                            Text(frame.capturedAt.stampTime)
                                .font(.system(size: 6, design: .monospaced))
                                .opacity(0.7)
                        }
                        .foregroundColor(Color(hex: "#E8670A").opacity(0.9))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)

                        // 선택 오버레이
                        if isSelecting {
                            Color.black.opacity(selectedFrames.contains(frame.id) ? 0.0 : 0.4)

                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: selectedFrames.contains(frame.id)
                                          ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(selectedFrames.contains(frame.id)
                                            ? Color(hex: "#C8762A") : .white.opacity(0.5))
                                        .padding(5)
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4.0/3.0, contentMode: .fit)
                    .clipped()
                    .onTapGesture {
                        if isSelecting {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if selectedFrames.contains(frame.id) {
                                    selectedFrames.remove(frame.id)
                                } else {
                                    selectedFrames.insert(frame.id)
                                }
                            }
                        } else {
                            selectedFrame = frame
                        }
                    }

                    if i < frames.count - 1 {
                        Color(hex: "#1A1005").frame(width: 2)
                    }
                }

                // 빈 칸 채우기
                if frames.count < 3 {
                    ForEach(0..<(3 - frames.count), id: \.self) { _ in
                        Color(hex: "#1A1005")
                            .frame(maxWidth: .infinity)
                            .aspectRatio(4.0/3.0, contentMode: .fit)
                    }
                }
            }
            .background(Color(hex: "#1A1005"))

            // 프레임 번호 + 메모 행
            memoRow(frames: frames, startIndex: startIndex)

            perforationRow(frameCount: 3)
        }
    }

    private func memoRow(frames: [Frame], startIndex: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                HStack(spacing: 4) {
                    Text(String(format: "%03d", startIndex + i + 1))
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.45))

                    if i < frames.count && !frames[i].memo.isEmpty {
                        Text(frames[i].memo)
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundColor(.white.opacity(0.25))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 5)
            }
        }
        .frame(height: 18)
        .background(Color(hex: "#150D04"))
    }

    // MARK: - Perforation Row

    private func perforationRow(frameCount: Int) -> some View {
        GeometryReader { geo in
            HStack(spacing: 6) {
                ForEach(0..<Int(geo.size.width / 19), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#0D0906"))
                        .frame(width: 13, height: 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 20)
        .background(Color(hex: "#1A1005"))
    }
}

// MARK: - Save Options Sheet

struct SaveOptionsSheet: View {
    let frames: [Frame]
    let roll: Roll
    let onDone: () -> Void

    @State private var showDate = true
    @State private var showFilmName = true
    @State private var showPerforation = true
    @State private var showMemo = false
    @State private var saveAsStrip = false
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var showPermissionAlert = false
    @State private var currentPreviewIndex = 0

    private var canSaveAsStrip: Bool { frames.count > 1 }

    var body: some View {
        ZStack {
            Color(hex: "#0D0906").ignoresSafeArea()

            VStack(spacing: 0) {
                // 핸들
                Capsule()
                    .fill(Color(hex: "#C8762A").opacity(0.3))
                    .frame(width: 32, height: 3)
                    .padding(.top, 14)

                // 타이틀
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DEVELOP")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                            .tracking(3)
                        Text("\(frames.count)장의 사진")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    // 필름 캐니스터 아이콘
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(roll.filmStock.dimmedCanisterColor.opacity(0.15))
                            .frame(width: 36, height: 44)
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(roll.filmStock.dimmedCanisterColor.opacity(0.3), lineWidth: 1)
                            .frame(width: 36, height: 44)
                        Text(roll.filmStock.name.prefix(2).uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(roll.filmStock.dimmedCanisterColor.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 프리뷰
                        previewSection

                        // 옵션 카드
                        optionCard

                        // 스트립 옵션
                        if canSaveAsStrip {
                            stripCard
                        }

                        // 저장 버튼
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
        }
        .overlay {
            if saveSuccess {
                saveSuccessOverlay
            }
        }
        .alert("사진 접근 권한이 필요합니다", isPresented: $showPermissionAlert) {
            Button("설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("설정 > FilmRoll > 사진에서 권한을 허용해주세요.")
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("PREVIEW")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.4))
                    .tracking(3)
                Spacer()
            }

            if saveAsStrip && canSaveAsStrip {
                stripPreview
            } else {
                singlePreview
            }
        }
    }

    private var singlePreview: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentPreviewIndex) {
                ForEach(Array(frames.enumerated()), id: \.element.id) { index, frame in
                    singlePreviewCard(frame: frame)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: frames.count > 1 ? .automatic : .never))
            .aspectRatio(showPerforation ? (4.0/3.0 * 0.85) : (4.0/3.0), contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: roll.filmStock.dimmedCanisterColor.opacity(0.15), radius: 20, x: 0, y: 8)

            if frames.count > 1 {
                Text("\(currentPreviewIndex + 1) / \(frames.count)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
            }
        }
    }

    private func singlePreviewCard(frame: Frame) -> some View {
        VStack(spacing: 0) {
            if showPerforation {
                previewPerforationStrip(label: nil)
            }

            ZStack(alignment: .bottomTrailing) {
                // 이미지 (캡처 시 이미 색감 적용됨)
                Group {
                    if let data = frame.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(hex: "#2B1E0F")
                    }
                }
                .aspectRatio(4.0/3.0, contentMode: .fit)
                .clipped()

                // 날짜 스탬프
                if showDate {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(frame.capturedAt.stampDate)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        Text(frame.capturedAt.stampTime)
                            .font(.system(size: 9, design: .monospaced))
                            .opacity(0.7)
                    }
                    .foregroundColor(Color(hex: "#E8670A"))
                    .padding(8)
                }

                // 필름 이름 (왼쪽 아래)
                if showFilmName {
                    VStack {
                        Spacer()
                        HStack {
                            Text(roll.filmStock.name.uppercased())
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#E8670A"))
                            Spacer()
                        }
                        .padding(8)
                    }
                }
            }

            if showPerforation {
                previewPerforationStrip(label: showMemo ? frame.memo : nil)
            }
        }
        .background(Color(hex: "#1A1005"))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var stripPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    if showPerforation {
                        previewStripPerforation(count: frames.count, label: nil)
                    }
                    HStack(spacing: 2) {
                        ForEach(frames) { frame in
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let data = frame.imageData, let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 75)
                                            .clipped()
                                    } else {
                                        Color(hex: "#2B1E0F").frame(width: 100, height: 75)
                                    }
                                }
                                if showDate {
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text(frame.capturedAt.stampDate)
                                            .font(.system(size: 6, weight: .semibold, design: .monospaced))
                                        Text(frame.capturedAt.stampTime)
                                            .font(.system(size: 5, design: .monospaced))
                                            .opacity(0.7)
                                    }
                                    .foregroundColor(Color(hex: "#E8670A"))
                                    .padding(4)
                                }
                                if showFilmName {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Text(roll.filmStock.name.uppercased())
                                                .font(.system(size: 6, weight: .semibold, design: .monospaced))
                                                .foregroundColor(Color(hex: "#E8670A"))
                                            Spacer()
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .frame(width: 100, height: 75)
                        }
                    }
                    .background(Color(hex: "#1A1005"))
                    if showPerforation {
                        previewStripPerforation(count: frames.count, label: showMemo ? frames.first?.memo : nil)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal, 2)
        }
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    }

    // 단일 프레임용 퍼포레이션
    private func previewPerforationStrip(label: String?) -> some View {
        ZStack {
            Color(hex: "#1A1005")
            HStack(spacing: 5) {
                ForEach(0..<18, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(hex: "#0D0906"))
                        .frame(width: 10, height: 7)
                }
            }
            if let label, !label.isEmpty {
                HStack {
                    Spacer()
                    Text(label)
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.trailing, 8)
                }
            }
        }
        .frame(height: 18)
    }

    // 스트립용 퍼포레이션
    private func previewStripPerforation(count: Int, label: String?) -> some View {
        ZStack {
            Color(hex: "#1A1005")
            HStack(spacing: 5) {
                ForEach(0..<(count * 4), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(hex: "#0D0906"))
                        .frame(width: 10, height: 7)
                }
            }
        }
        .frame(height: 18)
    }

    // MARK: - Option Card

    private var optionCard: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.6))
                Text("현상 옵션")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#C8762A").opacity(0.06))

            Divider().background(Color(hex: "#C8762A").opacity(0.1))

            optionRow(title: "날짜 · 시간", icon: "clock.fill", isOn: $showDate)
            thinDivider
            optionRow(title: "필름 이름", icon: "film.fill", isOn: $showFilmName)
            thinDivider
            optionRow(title: "퍼포레이션", icon: "rectangle.split.3x1.fill", isOn: $showPerforation)
            thinDivider
            optionRow(title: "메모 (아래 퍼포레이션)", icon: "text.alignleft", isOn: $showMemo)
                .opacity(showPerforation ? 1.0 : 0.4)
                .disabled(!showPerforation)
        }
        .background(Color(hex: "#150D04"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#C8762A").opacity(0.12), lineWidth: 1))
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func optionRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(isOn.wrappedValue ? Color(hex: "#C8762A") : Color(hex: "#C8762A").opacity(0.3))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(isOn.wrappedValue ? 0.85 : 0.4))

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#C8762A")))
                .labelsHidden()
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .animation(.easeInOut(duration: 0.2), value: isOn.wrappedValue)
    }

    // MARK: - Strip Card

    private var stripCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "rectangle.split.3x1")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.6))
                Text("저장 형식")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#C8762A").opacity(0.06))

            Divider().background(Color(hex: "#C8762A").opacity(0.1))

            // 단일 / 스트립 선택
            HStack(spacing: 10) {
                formatButton(title: "단일 저장", subtitle: "\(frames.count)장 각각", icon: "photo", isSelected: !saveAsStrip) {
                    withAnimation(.easeInOut(duration: 0.2)) { saveAsStrip = false }
                }
                formatButton(title: "스트립", subtitle: "한 장으로", icon: "rectangle.split.3x1", isSelected: saveAsStrip) {
                    withAnimation(.easeInOut(duration: 0.2)) { saveAsStrip = true }
                }
            }
            .padding(14)
        }
        .background(Color(hex: "#150D04"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#C8762A").opacity(0.12), lineWidth: 1))
    }

    private func formatButton(title: String, subtitle: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? Color(hex: "#C8762A") : .white.opacity(0.25))
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .white.opacity(0.3))
                Text(subtitle)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(isSelected ? Color(hex: "#C8762A").opacity(0.6) : .white.opacity(0.15))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color(hex: "#C8762A").opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#C8762A").opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1)
            )
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: performSave) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(Color(hex: "#1C1209"))
                        .scaleEffect(0.8)
                    Text("현상 중...")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#1C1209").opacity(0.7))
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14))
                    Text(saveAsStrip && canSaveAsStrip ? "스트립으로 현상" : "\(frames.count)장 현상")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                }
            }
            .foregroundColor(Color(hex: "#1C1209"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSaving ? Color(hex: "#C8762A").opacity(0.5) : Color(hex: "#C8762A"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color(hex: "#C8762A").opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .disabled(isSaving)
    }

    // MARK: - Save Success Overlay

    private var saveSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(Color(hex: "#C8762A"))
                Text("현상 완료")
                    .font(.system(size: 15, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Save Logic

    private func performSave() {
        isSaving = true
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                await MainActor.run { isSaving = false; showPermissionAlert = true }
                return
            }
            if saveAsStrip && canSaveAsStrip {
                if let img = renderStrip() { await saveToPhotos(img) }
            } else {
                for frame in frames {
                    if let img = renderSingleFrame(frame) { await saveToPhotos(img) }
                }
            }
            await MainActor.run {
                isSaving = false
                withAnimation { saveSuccess = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await MainActor.run { onDone() }
                }
            }
        }
    }

    private func saveToPhotos(_ image: UIImage) async {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { _, _ in cont.resume() }
        }
    }

    // MARK: - Single Frame Export

    private func renderSingleFrame(_ frame: Frame) -> UIImage? {
        guard let data = frame.imageData, let img = UIImage(data: data) else { return nil }
        let exportW: CGFloat = 1200
        let perfH: CGFloat = showPerforation ? 44 : 0
        let imageH: CGFloat = exportW * 3.0 / 4.0
        let exportH: CGFloat = perfH + imageH + perfH

        let renderer = ImageRenderer(
            content: SingleFrameExportView(
                image: img, frame: frame, roll: roll,
                showDate: showDate, showFilmName: showFilmName,
                showPerforation: showPerforation, showMemo: showMemo,
                exportW: exportW, exportH: exportH, perfH: perfH
            )
            .frame(width: exportW, height: exportH)
            .environment(\.colorScheme, .dark)
        )
        renderer.scale = 3.0
        renderer.proposedSize = ProposedViewSize(width: exportW, height: exportH)
        return renderer.uiImage
    }

    // MARK: - Strip Export

    private func renderStrip() -> UIImage? {
        let frameW: CGFloat = 400
        let frameH: CGFloat = 300
        let perfH: CGFloat = showPerforation ? 44 : 0
        let gap: CGFloat = 3
        let totalW: CGFloat = frameW * CGFloat(frames.count) + gap * CGFloat(frames.count - 1)
        let totalH: CGFloat = perfH + frameH + perfH

        let renderer = ImageRenderer(
            content: StripExportView(
                frames: frames, roll: roll,
                showDate: showDate, showFilmName: showFilmName,
                showPerforation: showPerforation, showMemo: showMemo,
                frameW: frameW, frameH: frameH, perfH: perfH, gap: gap
            )
            .frame(width: totalW, height: totalH)
            .environment(\.colorScheme, .dark)
        )
        renderer.scale = 3.0
        renderer.proposedSize = ProposedViewSize(width: totalW, height: totalH)
        return renderer.uiImage
    }
}

// MARK: - Single Frame Export View

private struct SingleFrameExportView: View {
    let image: UIImage
    let frame: Frame
    let roll: Roll
    let showDate: Bool
    let showFilmName: Bool
    let showPerforation: Bool
    let showMemo: Bool
    let exportW: CGFloat
    let exportH: CGFloat
    let perfH: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            // 상단 퍼포레이션
            if showPerforation {
                exportPerforationRow(memo: nil)
            }

            // 사진 영역
            ZStack(alignment: .bottom) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                // 날짜 (오른쪽 아래) + 필름이름 (왼쪽 아래)
                HStack(alignment: .bottom) {
                    // 필름 이름 왼쪽
                    if showFilmName {
                        Text(roll.filmStock.name.uppercased())
                            .font(.system(size: exportW * 0.018, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#E8670A"))
                    }
                    Spacer()
                    // 날짜 오른쪽
                    if showDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(frame.capturedAt.stampDate)
                                .font(.system(size: exportW * 0.022, weight: .semibold, design: .monospaced))
                            Text(frame.capturedAt.stampTime)
                                .font(.system(size: exportW * 0.017, design: .monospaced))
                                .opacity(0.75)
                        }
                        .foregroundColor(Color(hex: "#E8670A"))
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: exportW * 3.0 / 4.0)

            // 하단 퍼포레이션 (메모 포함)
            if showPerforation {
                exportPerforationRow(memo: showMemo ? frame.memo : nil)
            }
        }
        .background(Color(hex: "#1A1005"))
    }

    private func exportPerforationRow(memo: String?) -> some View {
        ZStack {
            Color(hex: "#1A1005")
            // 퍼포레이션 구멍들
            HStack(spacing: 10) {
                ForEach(0..<28, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#0D0906"))
                        .frame(width: 22, height: 14)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // 메모
            if let memo, !memo.isEmpty {
                HStack {
                    Spacer()
                    Text(memo)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.trailing, 16)
                }
            }
        }
        .frame(height: perfH)
    }
}

// MARK: - Strip Export View

private struct StripExportView: View {
    let frames: [Frame]
    let roll: Roll
    let showDate: Bool
    let showFilmName: Bool
    let showPerforation: Bool
    let showMemo: Bool
    let frameW: CGFloat
    let frameH: CGFloat
    let perfH: CGFloat
    let gap: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            if showPerforation {
                stripPerforationRow(memo: nil)
            }

            HStack(spacing: gap) {
                ForEach(frames) { frame in
                    ZStack(alignment: .bottom) {
                        if let data = frame.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: frameW, height: frameH)
                                .clipped()
                        } else {
                            Color(hex: "#2B1E0F").frame(width: frameW, height: frameH)
                        }

                        HStack(alignment: .bottom) {
                            if showFilmName {
                                Text(roll.filmStock.name.uppercased())
                                    .font(.system(size: frameW * 0.038, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color(hex: "#E8670A"))
                            }
                            Spacer()
                            if showDate {
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(frame.capturedAt.stampDate)
                                        .font(.system(size: frameW * 0.038, weight: .semibold, design: .monospaced))
                                    Text(frame.capturedAt.stampTime)
                                        .font(.system(size: frameW * 0.03, design: .monospaced))
                                        .opacity(0.75)
                                }
                                .foregroundColor(Color(hex: "#E8670A"))
                            }
                        }
                        .padding(8)
                    }
                    .frame(width: frameW, height: frameH)
                }
            }
            .background(Color(hex: "#1A1005"))

            if showPerforation {
                stripPerforationRow(memo: showMemo ? frames.first?.memo : nil)
            }
        }
        .background(Color(hex: "#1A1005"))
    }

    private func stripPerforationRow(memo: String?) -> some View {
        let holeCount = max(frames.count * 5, 8)
        return ZStack {
            Color(hex: "#1A1005")
            HStack(spacing: 10) {
                ForEach(0..<holeCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#0D0906"))
                        .frame(width: 22, height: 14)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            if let memo, !memo.isEmpty {
                HStack {
                    Spacer()
                    Text(memo)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.trailing, 16)
                }
            }
        }
        .frame(height: perfH)
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
