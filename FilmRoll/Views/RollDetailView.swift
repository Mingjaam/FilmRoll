import SwiftUI
import Photos
import ImageIO

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
            let decoded = await Task.detached(priority: .utility) {
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 300
                ]
                guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
                else { return UIImage(data: data) }
                return UIImage(cgImage: cgImage)
            }.value
            guard !Task.isCancelled else { return }
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
    @State private var isEditingName = false
    @State private var editingName: String = ""
    @FocusState private var nameFieldFocused: Bool

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

                    LazyVStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowFrames in
                            filmRow(frames: rowFrames, startIndex: rowIndex * 3)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }


        }
        .onTapGesture {
            if isEditingName { commitEditName() }
        }
        .sheet(item: $selectedFrame) { frame in
            FrameDetailView(frame: frame, filmStock: roll.filmStock)
        }
        .alert("이 순간들을 놓아줄까요?", isPresented: $showDeleteConfirm) {
            Button("아직은 간직할게요", role: .cancel) { }
            Button("\(selectedFrames.count)장의 기억 보내기", role: .destructive) {
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
            Text("한번 떠난 순간은 다시 돌아오지 않아요.")
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

    // MARK: - Name Edit

    private func commitEditName() {
        nameFieldFocused = false
        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        roll.customName = trimmed.isEmpty ? nil : trimmed
        withAnimation(.easeInOut(duration: 0.15)) {
            isEditingName = false
            editingName = ""
        }
    }

    private var displayName: String {
        if let name = roll.customName, !name.isEmpty { return name }
        return "Roll \(String(format: "%02d", roll.number))"
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

            VStack(spacing: 3) {
                Text("ROLL \(String(format: "%02d", roll.number))  ·  \(roll.filmStock.name.uppercased())")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                    .tracking(2)

                if isEditingName {
                    TextField("", text: $editingName)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { commitEditName() }
                        .overlay(
                            Group {
                                if editingName.isEmpty {
                                    Text("Roll \(String(format: "%02d", roll.number))")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(.white.opacity(0.25))
                                        .allowsHitTesting(false)
                                }
                            }
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#C8762A").opacity(0.4), lineWidth: 1))
                } else {
                    Button(action: {
                        editingName = roll.customName ?? ""
                        withAnimation(.easeInOut(duration: 0.15)) { isEditingName = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { nameFieldFocused = true }
                    }) {
                        HStack(spacing: 4) {
                            Text(displayName)
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(roll.customName?.isEmpty == false ? .white.opacity(0.75) : .white.opacity(0.4))
                                .lineLimit(1)
                            Image(systemName: "pencil")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "#C8762A").opacity(0.4))
                        }
                    }
                }

                Text(roll.dateRangeLabel)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            HStack(spacing: 8) {
                if isSelecting && !selectedFrames.isEmpty {
                    Button(action: { showSaveSheet = true }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.8))
                    }
                    .transition(.scale.combined(with: .opacity))

                    Button(action: { showDeleteConfirm = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.8))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Button(action: {
                    if isEditingName {
                        commitEditName()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelecting.toggle()
                            if !isSelecting { selectedFrames = [] }
                        }
                    }
                }) {
                    Image(systemName: isEditingName ? "checkmark.circle.fill" : (isSelecting ? "checkmark.circle.fill" : "checkmark.circle"))
                        .font(.system(size: 18))
                        .foregroundColor(isEditingName ? Color(hex: "#C8762A") : Color(hex: "#C8762A").opacity(0.8))
                }
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

    /// 임시 파일 경로 + 메타데이터 (imageData를 메모리에 보관하지 않음)
    private struct FrameFileRef {
        let fileURL: URL
        let capturedAt: Date
        let memo: String
    }

    private func performSave() {
        isSaving = true

        // 1단계: imageData를 임시 파일로 내보내고 메모리에서 해제
        //   SwiftData는 imageData 접근 시 fault-in하므로, 파일로 쓴 뒤 참조를 끊으면
        //   SwiftData가 내부 캐시를 정리할 수 있음
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("filmroll_export_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var fileRefs: [FrameFileRef] = []
        for (i, frame) in frames.enumerated() {
            autoreleasepool {
                guard let data = frame.imageData else { return }
                let fileURL = tempDir.appendingPathComponent("frame_\(i).jpg")
                try? data.write(to: fileURL)
                fileRefs.append(FrameFileRef(fileURL: fileURL, capturedAt: frame.capturedAt, memo: frame.memo))
            }
        }

        let filmStock = roll.filmStock
        let localShowDate = showDate
        let localShowFilmName = showFilmName
        let localShowPerforation = showPerforation
        let localShowMemo = showMemo
        let localSaveAsStrip = saveAsStrip
        let localCanSaveAsStrip = canSaveAsStrip

        Task.detached(priority: .userInitiated) {
            defer {
                // 임시 파일 정리
                try? FileManager.default.removeItem(at: tempDir)
            }

            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                await MainActor.run { isSaving = false; showPermissionAlert = true }
                return
            }
            if localSaveAsStrip && localCanSaveAsStrip {
                // 스트립: 최대 6장씩 분할하여 메모리 관리
                let chunks = fileRefs.chunked(into: 6)
                for chunk in chunks {
                    autoreleasepool {
                        if let img = Self.renderStripCG(
                            refs: chunk, filmStock: filmStock,
                            showDate: localShowDate, showFilmName: localShowFilmName,
                            showPerforation: localShowPerforation, showMemo: localShowMemo
                        ) {
                            Self.saveToPhotosSync(img)
                        }
                    }
                }
            } else {
                // 단일: 한 장씩 URL에서 다운샘플 → 렌더 → 저장 → 메모리 해제
                for ref in fileRefs {
                    autoreleasepool {
                        if let img = Self.renderSingleFrameCG(
                            ref: ref, filmStock: filmStock,
                            showDate: localShowDate, showFilmName: localShowFilmName,
                            showPerforation: localShowPerforation, showMemo: localShowMemo
                        ) {
                            Self.saveToPhotosSync(img)
                        }
                    }
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

    private static func saveToPhotosSync(_ image: UIImage) {
        let semaphore = DispatchSemaphore(value: 0)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { _, _ in semaphore.signal() }
        semaphore.wait()
    }

    // MARK: - Downsampled Image Loading (메모리 효율적)

    /// URL에서 직접 디코딩 — Data를 메모리에 올리지 않고 CGImageSource가 파일을 직접 읽음
    private static func downsampledImage(url: URL, maxPixelWidth: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else { return nil }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelWidth
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Single Frame Export (CGContext)

    private static func renderSingleFrameCG(
        ref: FrameFileRef, filmStock: FilmStock,
        showDate: Bool, showFilmName: Bool,
        showPerforation: Bool, showMemo: Bool
    ) -> UIImage? {
        // 출력에 필요한 만큼만 디코딩 (2400px) — 원본 4032px 전체 로드 방지
        let scale: CGFloat = 2.0
        let exportW: CGFloat = 1200
        let targetPixelW = exportW * scale
        guard let img = downsampledImage(url: ref.fileURL, maxPixelWidth: targetPixelW) else { return nil }
        let perfH: CGFloat = showPerforation ? 44 : 0
        let imageH: CGFloat = exportW * 3.0 / 4.0
        let exportH: CGFloat = perfH + imageH + perfH

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: exportW, height: exportH), format: format)

        return renderer.image { ctx in
            let gc = ctx.cgContext
            // 배경
            UIColor(red: 0.102, green: 0.063, blue: 0.024, alpha: 1).setFill() // #1A1005
            gc.fill(CGRect(x: 0, y: 0, width: exportW, height: exportH))

            var y: CGFloat = 0

            // 상단 퍼포레이션
            if showPerforation {
                drawPerforation(in: gc, rect: CGRect(x: 0, y: y, width: exportW, height: perfH))
                y += perfH
            }

            // 사진
            img.draw(in: CGRect(x: 0, y: y, width: exportW, height: imageH))

            // 스탬프 텍스트
            let stampColor = UIColor(red: 0.91, green: 0.40, blue: 0.04, alpha: 1.0) // #E8670A

            if showFilmName {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: exportW * 0.018, weight: .semibold),
                    .foregroundColor: stampColor
                ]
                let name = filmStock.name.uppercased() as NSString
                name.draw(at: CGPoint(x: 16, y: y + imageH - 30), withAttributes: attrs)
            }

            if showDate {
                let dateAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: exportW * 0.022, weight: .semibold),
                    .foregroundColor: stampColor
                ]
                let timeAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: exportW * 0.017, weight: .regular),
                    .foregroundColor: stampColor.withAlphaComponent(0.75)
                ]
                let dateStr = ref.capturedAt.stampDate as NSString
                let timeStr = ref.capturedAt.stampTime as NSString
                let dateSize = dateStr.size(withAttributes: dateAttrs)
                let timeSize = timeStr.size(withAttributes: timeAttrs)
                dateStr.draw(at: CGPoint(x: exportW - dateSize.width - 16, y: y + imageH - dateSize.height - timeSize.height - 12), withAttributes: dateAttrs)
                timeStr.draw(at: CGPoint(x: exportW - timeSize.width - 16, y: y + imageH - timeSize.height - 8), withAttributes: timeAttrs)
            }

            y += imageH

            // 하단 퍼포레이션 + 메모
            if showPerforation {
                drawPerforation(in: gc, rect: CGRect(x: 0, y: y, width: exportW, height: perfH))
                if showMemo && !ref.memo.isEmpty {
                    let memoAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                        .foregroundColor: UIColor.white.withAlphaComponent(0.3)
                    ]
                    let memoStr = ref.memo as NSString
                    let memoSize = memoStr.size(withAttributes: memoAttrs)
                    memoStr.draw(at: CGPoint(x: exportW - memoSize.width - 16, y: y + (perfH - memoSize.height) / 2), withAttributes: memoAttrs)
                }
            }
        }
    }

    // MARK: - Strip Export (CGContext)

    private static func renderStripCG(
        refs: [FrameFileRef], filmStock: FilmStock,
        showDate: Bool, showFilmName: Bool,
        showPerforation: Bool, showMemo: Bool
    ) -> UIImage? {
        let scale: CGFloat = 2.0
        let frameW: CGFloat = 400
        let frameH: CGFloat = 300
        let perfH: CGFloat = showPerforation ? 44 : 0
        let gap: CGFloat = 3
        let totalW: CGFloat = frameW * CGFloat(refs.count) + gap * CGFloat(max(0, refs.count - 1))
        let totalH: CGFloat = perfH + frameH + perfH

        // 장수가 많을수록 각 프레임 디코딩 해상도를 낮춰 메모리 절약
        let count = refs.count
        let maxPixelW: CGFloat
        switch count {
        case ...6:   maxPixelW = 800   // 1-6장: 원본 품질
        case 7...12: maxPixelW = 600   // 7-12장
        case 13...18: maxPixelW = 450  // 13-18장
        default:     maxPixelW = 320   // 19장 이상
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalW, height: totalH), format: format)

        return renderer.image { ctx in
            let gc = ctx.cgContext
            // 배경
            UIColor(red: 0.102, green: 0.063, blue: 0.024, alpha: 1).setFill()
            gc.fill(CGRect(x: 0, y: 0, width: totalW, height: totalH))

            // 상단 퍼포레이션
            if showPerforation {
                drawPerforation(in: gc, rect: CGRect(x: 0, y: 0, width: totalW, height: perfH))
            }

            let stampColor = UIColor(red: 0.91, green: 0.40, blue: 0.04, alpha: 1.0)

            for (i, ref) in refs.enumerated() {
                let x = CGFloat(i) * (frameW + gap)
                let y = perfH

                // 장수에 따라 조정된 해상도로 디코딩
                if let img = downsampledImage(url: ref.fileURL, maxPixelWidth: maxPixelW) {
                    img.draw(in: CGRect(x: x, y: y, width: frameW, height: frameH))
                }

                if showFilmName {
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.monospacedSystemFont(ofSize: frameW * 0.038, weight: .semibold),
                        .foregroundColor: stampColor
                    ]
                    let name = filmStock.name.uppercased() as NSString
                    name.draw(at: CGPoint(x: x + 8, y: y + frameH - 22), withAttributes: attrs)
                }

                if showDate {
                    let dateAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.monospacedSystemFont(ofSize: frameW * 0.038, weight: .semibold),
                        .foregroundColor: stampColor
                    ]
                    let timeAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.monospacedSystemFont(ofSize: frameW * 0.03, weight: .regular),
                        .foregroundColor: stampColor.withAlphaComponent(0.75)
                    ]
                    let dateStr = ref.capturedAt.stampDate as NSString
                    let timeStr = ref.capturedAt.stampTime as NSString
                    let dateSize = dateStr.size(withAttributes: dateAttrs)
                    let timeSize = timeStr.size(withAttributes: timeAttrs)
                    dateStr.draw(at: CGPoint(x: x + frameW - dateSize.width - 8, y: y + frameH - dateSize.height - timeSize.height - 6), withAttributes: dateAttrs)
                    timeStr.draw(at: CGPoint(x: x + frameW - timeSize.width - 8, y: y + frameH - timeSize.height - 4), withAttributes: timeAttrs)
                }
            }

            // 하단 퍼포레이션 + 메모
            if showPerforation {
                let bottomY = perfH + frameH
                drawPerforation(in: gc, rect: CGRect(x: 0, y: bottomY, width: totalW, height: perfH))
                if showMemo, let firstMemo = refs.first?.memo, !firstMemo.isEmpty {
                    let memoAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                        .foregroundColor: UIColor.white.withAlphaComponent(0.3)
                    ]
                    let memoStr = firstMemo as NSString
                    let memoSize = memoStr.size(withAttributes: memoAttrs)
                    memoStr.draw(at: CGPoint(x: totalW - memoSize.width - 16, y: bottomY + (perfH - memoSize.height) / 2), withAttributes: memoAttrs)
                }
            }
        }
    }

    // MARK: - Perforation Drawing Helper

    private static func drawPerforation(in gc: CGContext, rect: CGRect) {
        // 배경은 이미 #1A1005로 칠해짐
        let holeW: CGFloat = 22
        let holeH: CGFloat = 14
        let spacing: CGFloat = 10
        let holeColor = UIColor(red: 0.051, green: 0.035, blue: 0.024, alpha: 1) // #0D0906
        let totalSlot = holeW + spacing
        let count = Int(rect.width / totalSlot)
        let startX = rect.minX + (rect.width - CGFloat(count) * totalSlot + spacing) / 2

        holeColor.setFill()
        for i in 0..<count {
            let x = startX + CGFloat(i) * totalSlot
            let y = rect.minY + (rect.height - holeH) / 2
            let holePath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: holeW, height: holeH), cornerRadius: 3)
            holePath.fill()
        }
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
