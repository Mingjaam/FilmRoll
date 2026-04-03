import SwiftUI
import SwiftData
import AVFoundation
import UIKit

struct MainView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Roll.number, order: .reverse) private var rolls: [Roll]

    @StateObject private var camera = CameraManager()
    @State private var showFlash = false
    @State private var showRollComplete = false
    @State private var isCapturing = false
    @State private var showStorage = false
    @State private var currentFrameIndex = 0

    private var activeRoll: Roll {
        if let roll = rolls.first(where: { !$0.isComplete }) {
            return roll
        }
        let newRoll = Roll(number: (rolls.map(\.number).max() ?? 0) + 1)
        context.insert(newRoll)
        return newRoll
    }

    var body: some View {
        ZStack {
            // 배경
            Color(hex: "#111111").ignoresSafeArea()

            VStack(spacing: 0) {
                // 상단 헤더
                headerView

                Spacer()

                // 필름 스트립 (카메라 프리뷰 포함)
                filmStripWithCamera

                Spacer()

                // 진행 바
                RollProgressView(frameCount: activeRoll.frameCount)
                    .padding(.bottom, 16)

                // 셔터 버튼
                ShutterButton(isCapturing: isCapturing) {
                    Task { await capturePhoto() }
                }
                .padding(.bottom, 48)
            }

            // 플래시 효과
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // 롤 완성 오버레이
            if showRollComplete {
                RollCompleteView(rollNumber: activeRoll.number) {
                    showRollComplete = false
                }
            }
        }
        .sheet(isPresented: $showStorage) {
            StorageBoxView()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ROLL \(String(format: "%02d", activeRoll.number))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                    .tracking(3)

                Text(Date.now.stampDate)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: { showStorage = true }) {
                VStack(spacing: 3) {
                    // 캐니스터 미니 아이콘
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

    private var filmStripWithCamera: some View {
        GeometryReader { geo in
            let frameWidth = geo.size.width * 0.78
            let frameHeight = frameWidth * (3.0 / 4.0)
            let stripHeight = frameHeight + 52

            VStack(spacing: 0) {
                PerforationStrip(width: geo.size.width)

                ZStack {
                    Color(hex: "#1C1209")

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 3) {
                                // 앞 패딩
                                Spacer().frame(width: (geo.size.width - frameWidth) / 2)

                                // 찍힌 프레임들
                                ForEach(Array(activeRoll.sortedFrames.enumerated()), id: \.element.id) { i, frame in
                                    FrameView(frame: frame, index: i, isCurrent: false)
                                        .frame(width: frameWidth, height: frameHeight)
                                        .id("frame_\(i)")
                                }

                                // 현재 빈 프레임 (카메라 프리뷰)
                                ZStack {
                                    CameraPreviewView(manager: camera)
                                        .frame(width: frameWidth, height: frameHeight)
                                        .clipShape(RoundedRectangle(cornerRadius: 1))
                                    FilmGrainView()
                                        .frame(width: frameWidth, height: frameHeight)
                                }
                                .id("camera")

                                // 다음 빈 프레임
                                FrameView(frame: nil, index: activeRoll.frameCount + 1, isCurrent: false)
                                    .frame(width: frameWidth, height: frameHeight)
                                    .opacity(0.5)

                                // 뒤 패딩
                                Spacer().frame(width: (geo.size.width - frameWidth) / 2)
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .onChange(of: activeRoll.frameCount) { _, _ in
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

                // 프레임 번호
                HStack {
                    Spacer()
                    Text(String(format: "%03d", activeRoll.frameCount + 1))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.6))
                    Spacer()
                }
                .frame(height: 16)
                .background(Color(hex: "#1C1209"))
            }
            .frame(height: stripHeight + 16)
        }
        .frame(height: UIScreen.main.bounds.width * 0.78 * 0.75 + 52 + 16)
    }

    // MARK: - Capture

    private func capturePhoto() async {
        guard !isCapturing, !activeRoll.isComplete else { return }
        isCapturing = true

        // 햅틱
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        // 플래시
        withAnimation(.easeOut(duration: 0.08)) { showFlash = true }
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.easeIn(duration: 0.15)) { showFlash = false }

        // 사진 캡처
        guard let image = await camera.capture() else {
            isCapturing = false
            return
        }

        // 현상 딜레이 (0.3초)
        try? await Task.sleep(for: .milliseconds(300))

        // 저장
        let compressed = image.jpegData(compressionQuality: 0.82)
        let frame = Frame(
            imageData: compressed,
            capturedAt: .now,
            orderIndex: activeRoll.frameCount
        )
        activeRoll.frames.append(frame)

        // 성공 햅틱
        let notify = UINotificationFeedbackGenerator()
        notify.notificationOccurred(.success)

        isCapturing = false

        // 36장 완성 체크
        if activeRoll.isFull {
            activeRoll.isComplete = true
            activeRoll.endDate = .now
            try? await Task.sleep(for: .milliseconds(800))
            showRollComplete = true
        }
    }
}
