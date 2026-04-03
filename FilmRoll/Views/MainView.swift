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
    @State private var showFilmPicker = false
    @State private var completedRollNumber = 1
    @State private var completedFilmName = ""
    @State private var completedFrameCount = 36

    private var activeRoll: Roll? {
        rolls.first(where: { !$0.isComplete })
    }

    var body: some View {
        ZStack {
            Color(hex: "#111111").ignoresSafeArea()

            if let roll = activeRoll {
                VStack(spacing: 0) {
                    headerView(roll: roll)
                    Spacer()
                    filmStripWithCamera(roll: roll)
                    Spacer()
                    RollProgressView(frameCount: roll.frameCount, total: roll.filmStock.frameCount)
                        .padding(.bottom, 16)
                    ShutterButton(isCapturing: isCapturing) {
                        Task { await capturePhoto(roll: roll) }
                    }
                    .padding(.bottom, 48)
                }
            } else if !showFilmPicker && !showRollComplete {
                // 필름이 없을 때 빈 상태
                VStack(spacing: 20) {
                    Text("NO FILM LOADED")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8762A").opacity(0.4))
                        .tracking(3)

                    Button(action: { showFilmPicker = true }) {
                        Text("LOAD FILM")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(Color(hex: "#1C1209"))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#C8762A"))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            // 플래시 효과
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // 롤 완성 오버레이
            if showRollComplete {
                RollCompleteView(
                    rollNumber: completedRollNumber,
                    filmName: completedFilmName,
                    frameCount: completedFrameCount
                ) {
                    showRollComplete = false
                    showFilmPicker = true
                }
            }
        }
        .sheet(isPresented: $showStorage) {
            StorageBoxView()
        }
        .sheet(isPresented: $showFilmPicker) {
            FilmPickerView { stock in
                loadFilm(stock)
                showFilmPicker = false
            }
        }
        .task {
            if activeRoll == nil {
                showFilmPicker = true
            }
        }
    }

    // MARK: - Load Film

    private func loadFilm(_ stock: FilmStock) {
        let newRoll = Roll(
            number: (rolls.map(\.number).max() ?? 0) + 1,
            filmStockID: stock.id
        )
        context.insert(newRoll)
    }

    // MARK: - Header

    private func headerView(roll: Roll) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // 필름 이름
                Text(roll.filmStock.name.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: roll.filmStock.canisterHex).opacity(0.8))
                    .tracking(3)

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

    private func filmStripWithCamera(roll: Roll) -> some View {
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
                                Spacer().frame(width: (geo.size.width - frameWidth) / 2)

                                ForEach(Array(roll.sortedFrames.enumerated()), id: \.element.id) { i, frame in
                                    FrameView(frame: frame, index: i, isCurrent: false, filmStock: roll.filmStock)
                                        .frame(width: frameWidth, height: frameHeight)
                                        .id("frame_\(i)")
                                }

                                // 카메라 프리뷰
                                ZStack {
                                    CameraPreviewView(manager: camera)
                                        .frame(width: frameWidth, height: frameHeight)
                                        .clipShape(RoundedRectangle(cornerRadius: 1))
                                    FilmGrainView()
                                        .frame(width: frameWidth, height: frameHeight)
                                }
                                .id("camera")

                                FrameView(frame: nil, index: roll.frameCount + 1, isCurrent: false)
                                    .frame(width: frameWidth, height: frameHeight)
                                    .opacity(0.5)

                                Spacer().frame(width: (geo.size.width - frameWidth) / 2)
                            }
                            .scrollTargetLayout()
                        }
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
        .frame(height: UIScreen.main.bounds.width * 0.78 * 0.75 + 52 + 18)
    }

    // MARK: - Capture

    private func capturePhoto(roll: Roll) async {
        guard !isCapturing, !roll.isComplete else { return }
        isCapturing = true

        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        withAnimation(.easeOut(duration: 0.08)) { showFlash = true }
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.easeIn(duration: 0.15)) { showFlash = false }

        guard let image = await camera.capture() else {
            isCapturing = false
            return
        }

        try? await Task.sleep(for: .milliseconds(300))

        let compressed = image.jpegData(compressionQuality: 0.82)
        let frame = Frame(
            imageData: compressed,
            capturedAt: .now,
            orderIndex: roll.frameCount
        )
        roll.frames.append(frame)

        let notify = UINotificationFeedbackGenerator()
        notify.notificationOccurred(.success)

        isCapturing = false

        if roll.isFull {
            roll.isComplete = true
            roll.endDate = .now
            completedRollNumber = roll.number
            completedFilmName = roll.filmStock.name
            completedFrameCount = roll.frameCount
            try? await Task.sleep(for: .milliseconds(800))
            showRollComplete = true
        }
    }
}
