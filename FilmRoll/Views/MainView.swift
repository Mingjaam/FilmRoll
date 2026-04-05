import SwiftUI
import SwiftData
import AVFoundation
import UIKit
import WidgetKit

struct MainView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Roll.number, order: .reverse) private var rolls: [Roll]

    @StateObject private var camera = CameraManager()
    @State private var showFlash = false
    @State private var showRollComplete = false
    @State private var isCapturing = false
    @State private var showStorage = false
    @State private var showFilmPicker = false
    @State private var showEjectConfirm = false
    @State private var completedRollNumber = 1
    @State private var completedFilmName = ""
    @State private var completedFrameCount = 36
    @State private var completedFilmStock: FilmStock = FilmStock.all[0]
    @State private var showHome = false
    @State private var isProcessingComplete = false
    @State private var isRollCompleting = false
    @State private var isDraggingExposure = false
    @State private var exposureBaseValue: Float = 0
    @State private var isDraggingColor = false
    @State private var colorBaseValue: Float = 1.0

    private var activeRoll: Roll? {
        rolls.first(where: { !$0.isComplete })
    }

    var body: some View {
        ZStack {
            Color(hex: "#111111").ignoresSafeArea()

            if let roll = activeRoll {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        headerView(roll: roll)
                        Spacer(minLength: 0)
                        filmStripWithCamera(roll: roll, availableWidth: geo.size.width)
                        Spacer(minLength: 0)
                        RollProgressView(frameCount: roll.frameCount, total: roll.frameCountLimit)
                            .padding(.bottom, 12)
                        ShutterButton(isCapturing: isCapturing) {
                            Task { await capturePhoto(roll: roll) }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }

            // 플래시 효과
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // 롤 완성 처리 중 로딩 화면
            if isProcessingComplete {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Color(hex: "#C8762A"))
                            .scaleEffect(1.2)
                        Text("DEVELOPING...")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                            .tracking(3)
                    }
                }
                .transition(.opacity)
            }

            // 롤 완성 오버레이
            if showRollComplete {
                RollCompleteView(
                    rollNumber: completedRollNumber,
                    filmName: completedFilmName,
                    frameCount: completedFrameCount,
                    filmStock: completedFilmStock
                ) {
                    showRollComplete = false
                    showFilmPicker = true
                } onGoHome: {
                    showRollComplete = false
                    showHome = true
                }
            }
        }
        .alert("필름을 꺼내시겠어요?", isPresented: $showEjectConfirm, presenting: activeRoll) { roll in
            Button("계속 찍기", role: .cancel) { }
            Button("꺼내버리기", role: .destructive) {
                ejectRoll(roll)
            }
        } message: { roll in
            if roll.frameCount > 0 {
                Text("카메라를 열면 이미 담긴 \(roll.frameCount)장의 순간이 빛에 녹아 사라져요.\n한번 노출되면 되돌릴 수 없어요.")
            } else {
                Text("아직 찍은 건 없어요.\n다른 필름으로 교체할까요?")
            }
        }
        .sheet(isPresented: $showStorage) {
            StorageBoxView()
        }
        .sheet(isPresented: $showFilmPicker, onDismiss: {
            // 필름을 선택하지 않고 시트를 닫으면 홈으로 이동
            if activeRoll == nil && !showRollComplete && !isRollCompleting {
                showHome = true
            }
        }) {
            FilmPickerView { stock, frameCount in
                loadFilm(stock, frameCount: frameCount)
                showFilmPicker = false
            }
        }
        .fullScreenCover(isPresented: $showHome) {
            HomeView()
        }
        .task {
            if activeRoll == nil && !isProcessingComplete && !showRollComplete && !isRollCompleting {
                showHome = true
            }
        }
    }

    // MARK: - Widget Data

    private func saveWidgetData(roll: Roll) {
        let defaults = UserDefaults(suiteName: "group.com.filmroll")
        defaults?.set(roll.number,                      forKey: "filmroll.rollNumber")
        defaults?.set(roll.filmStock.name,              forKey: "filmroll.filmName")
        defaults?.set(roll.filmStock.canisterHex,       forKey: "filmroll.canisterHex")
        defaults?.set(roll.frameCount,                  forKey: "filmroll.frameCount")
        defaults?.set(roll.frameCountLimit,             forKey: "filmroll.totalFrames")
        defaults?.set(Date().timeIntervalSince1970,     forKey: "filmroll.lastCapture")
    }

    // MARK: - Eject Roll

    private func ejectRoll(_ roll: Roll) {
        context.delete(roll)
        showHome = true
    }

    // MARK: - Load Film

    private func loadFilm(_ stock: FilmStock, frameCount: Int) {
        let newRoll = Roll(
            number: (rolls.map(\.number).max() ?? 0) + 1,
            filmStockID: stock.id,
            frameCountLimit: frameCount
        )
        context.insert(newRoll)
    }

    // MARK: - Header

    private func headerView(roll: Roll) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // 필름 이름 + 교체 버튼
                Button(action: { showEjectConfirm = true }) {
                    HStack(spacing: 5) {
                        Text(roll.filmStock.name.uppercased())
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(roll.filmStock.dimmedCanisterColor.opacity(0.8))
                            .tracking(3)

                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 8))
                            .foregroundColor(roll.filmStock.dimmedCanisterColor.opacity(0.4))
                    }
                }

                Text("ROLL \(String(format: "%02d", roll.number))")
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                    .tracking(2)

                Text(Date.now.stampDate)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: { showStorage = true }) {
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#C8762A").opacity(0.8))
                        .frame(width: 22, height: 28)
                        .overlay(
                            Text(String(format: "%02d", rolls.filter(\.isComplete).count))
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#1C1209"))
                        )
                    Text("BOX")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                        .tracking(1)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Film Strip with Camera

    private func filmStripWithCamera(roll: Roll, availableWidth: CGFloat) -> some View {
        GeometryReader { geo in
            let frameWidth = geo.size.width * 0.78
            let frameHeight = frameWidth * (3.0 / 4.0)
            let stripHeight = frameHeight + 52

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)

                PerforationStrip(width: geo.size.width)

                ZStack {
                    Color(hex: "#241810")

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 3) {
                                ForEach(Array(roll.sortedFrames.enumerated()), id: \.element.id) { i, frame in
                                    FrameView(frame: frame, index: i, isCurrent: false, filmStock: roll.filmStock, allowFlip: true)
                                        .frame(width: frameWidth, height: frameHeight)
                                        .id("frame_\(i)")
                                }

                                // 카메라 프리뷰 (라이브 필터 적용)
                                ZStack {
                                    CameraPreviewView(manager: camera)
                                        .frame(width: frameWidth, height: frameHeight)
                                        .clipShape(RoundedRectangle(cornerRadius: 1))
                                        .applyFilmGradingWithIntensity(roll.filmStock, intensity: Double(camera.colorIntensity))
                                    FilmGrainView()
                                        .frame(width: frameWidth, height: frameHeight)

                                    // 필름 이름 + 날짜/시간 스탬프
                                    VStack {
                                        Spacer()
                                        HStack(alignment: .bottom) {
                                            Text(roll.filmStock.name.uppercased())
                                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                .foregroundColor(Color(hex: "#E8670A"))
                                                .opacity(0.85)
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 1) {
                                                Text(Date.now.stampDate)
                                                Text(Date.now.stampTime)
                                                    .opacity(0.7)
                                            }
                                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                                            .foregroundColor(Color(hex: "#E8670A"))
                                            .opacity(0.85)
                                        }
                                        .padding(.bottom, 6)
                                        .padding(.horizontal, 8)
                                    }

                                    // 왼쪽: 색감 감도 / 오른쪽: 노출 보정
                                    HStack(spacing: 0) {
                                        // 왼쪽 — 색감 감도 (droplet 아이콘)
                                        VStack(spacing: 5) {
                                            Spacer()
                                            if isDraggingColor || camera.colorIntensity < 0.95 {
                                                Text(String(format: "%.1f", camera.colorIntensity))
                                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(Color(hex: "#4AB8C8"))
                                            }
                                            Image(systemName: "drop.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(isDraggingColor
                                                    ? Color(hex: "#4AB8C8")
                                                    : .white.opacity(0.25))
                                            Spacer()
                                        }
                                        .frame(width: 30)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 5, coordinateSpace: .local)
                                                .onChanged { value in
                                                    if !isDraggingColor {
                                                        isDraggingColor = true
                                                        colorBaseValue = camera.colorIntensity
                                                    }
                                                    let delta = Float(-value.translation.height) / 120.0
                                                    // 범위: 0.0(원본) ~ 1.0(필터 100%)
                                                    let newVal = max(0.0, min(1.0, colorBaseValue + delta * 1.2))
                                                    camera.colorIntensity = newVal
                                                }
                                                .onEnded { _ in isDraggingColor = false }
                                        )

                                        Spacer()

                                        // 오른쪽 — 노출 보정 (sun 아이콘)
                                        VStack(spacing: 5) {
                                            Spacer()
                                            if isDraggingExposure || abs(camera.exposureBias) > 0.05 {
                                                Text(String(format: "%+.1f", camera.exposureBias))
                                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(Color(hex: "#C8762A"))
                                            }
                                            Image(systemName: "sun.max")
                                                .font(.system(size: 12))
                                                .foregroundColor(isDraggingExposure
                                                    ? Color(hex: "#C8762A")
                                                    : .white.opacity(0.25))
                                            Spacer()
                                        }
                                        .frame(width: 30)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 5, coordinateSpace: .local)
                                                .onChanged { value in
                                                    if !isDraggingExposure {
                                                        isDraggingExposure = true
                                                        exposureBaseValue = camera.exposureBias
                                                    }
                                                    let delta = Float(-value.translation.height) / 120.0
                                                    camera.setExposureBias(exposureBaseValue + delta * 2.5)
                                                }
                                                .onEnded { _ in isDraggingExposure = false }
                                        )
                                    }
                                }
                                .id("camera")

                                FrameView(frame: nil, index: roll.frameCount + 1, isCurrent: false)
                                    .frame(width: frameWidth, height: frameHeight)
                                    .opacity(0.5)
                            }
                            .scrollTargetLayout()
                        }
                        // Spacer 대신 contentMargins — snap 정확도 향상
                        .contentMargins(.horizontal, (geo.size.width - frameWidth) / 2, for: .scrollContent)
                        .scrollTargetBehavior(.viewAligned)
                        .onChange(of: roll.frameCount) { _, _ in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                proxy.scrollTo("camera", anchor: .center)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo("camera", anchor: .center)
                        }
                    }
                }
                .frame(height: frameHeight)

                PerforationStrip(width: geo.size.width)

                HStack {
                    Spacer()
                    Text(String(format: "%03d", roll.frameCount + 1))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.6))
                    Spacer()
                }
                .frame(height: 16)
                .background(Color(hex: "#241810"))

                Rectangle()
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 1)
            }
            .frame(height: stripHeight + 18)
            .shadow(color: .black.opacity(0.75), radius: 18, x: 0, y: 10)
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: -4)
        }
        .frame(height: availableWidth * 0.78 * 0.75 + 52 + 18)
    }

    // MARK: - Capture

    private func capturePhoto(roll: Roll) async {
        guard !isCapturing, !roll.isComplete else { return }
        isCapturing = true

        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        camera.playShutterSound()

        withAnimation(.easeOut(duration: 0.08)) { showFlash = true }
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.easeIn(duration: 0.15)) { showFlash = false }

        guard let image = await camera.capture() else {
            isCapturing = false
            return
        }

        try? await Task.sleep(for: .milliseconds(300))

        let colorIntensity = camera.colorIntensity
        let filmStock = roll.filmStock
        let cropped = image.croppedTo4x3()
        // SwiftUI ImageRenderer로 색감 굽기 — 카메라 프리뷰와 동일한 결과 보장
        let graded = cropped.applyGrading(stock: filmStock, colorIntensity: colorIntensity)
        let compressed = graded.jpegData(compressionQuality: 0.82)
        let frame = Frame(
            imageData: compressed,
            capturedAt: .now,
            orderIndex: roll.frameCount
        )
        roll.frames.append(frame)

        let notify = UINotificationFeedbackGenerator()
        notify.notificationOccurred(.success)

        isCapturing = false

        // 위젯 데이터 업데이트
        saveWidgetData(roll: roll)
        WidgetCenter.shared.reloadTimelines(ofKind: "filmroll_widget")

        if roll.isFull {
            isRollCompleting = true
            roll.isComplete = true
            roll.endDate = .now
            completedRollNumber = roll.number
            completedFilmName = roll.filmStock.name
            completedFrameCount = roll.frameCount
            completedFilmStock = roll.filmStock
            // 로딩 화면 표시
            withAnimation(.easeIn(duration: 0.3)) { isProcessingComplete = true }
            try? await Task.sleep(for: .milliseconds(1200))
            withAnimation(.easeOut(duration: 0.2)) { isProcessingComplete = false }
            try? await Task.sleep(for: .milliseconds(200))
            showRollComplete = true
            isRollCompleting = false
        }
    }
}
