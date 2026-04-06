import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Roll.number, order: .reverse) private var rolls: [Roll]

    @State private var navigateToCamera = false
    @State private var navigateToStorage = false
    @State private var showFilmPicker = false
    @State private var pendingNavigateToCamera = false
    @State private var logoAppeared = false
    @State private var contentAppeared = false

    private var activeRoll: Roll? {
        rolls.first(where: { !$0.isComplete })
    }

    private var completedCount: Int {
        rolls.filter(\.isComplete).count
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 배경 — 아주 미세한 그라디언트
                LinearGradient(
                    colors: [Color(hex: "#0D0906"), Color(hex: "#111111"), Color(hex: "#0A0804")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 배경 비네트 원 (allowsHitTesting false로 레이아웃에 영향 없음)
                Circle()
                    .fill(Color(hex: "#C8762A").opacity(0.04))
                    .frame(width: 500, height: 500)
                    .offset(x: -80, y: -200)
                    .blur(radius: 60)
                    .allowsHitTesting(false)

                Circle()
                    .fill(Color(hex: "#C8762A").opacity(0.03))
                    .frame(width: 300, height: 300)
                    .offset(x: 120, y: 280)
                    .blur(radius: 50)
                    .allowsHitTesting(false)

                // 전체 콘텐츠 — 명시적 너비 고정으로 오버플로 방지
                VStack(spacing: 0) {
                    Spacer().frame(height: geo.size.height * 0.1)

                    // 로고 + 앱명 섹션
                    VStack(spacing: 0) {
                        // 로고 이미지
                        Image("logoimg")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .opacity(logoAppeared ? 1 : 0)
                            .scaleEffect(logoAppeared ? 1 : 0.85)
                            .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1), value: logoAppeared)

                        Spacer().frame(height: 22)

                        // 앱 이름
                        Text("FILMROLL")
                            .font(.system(size: 26, weight: .ultraLight, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(8)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 8)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: contentAppeared)

                        Spacer().frame(height: 8)

                        // 영문 감성 문구
                        Text("every moment deserves a frame")
                            .font(.system(size: 11, weight: .light, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.55))
                            .tracking(1.0)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 6)
                            .animation(.easeOut(duration: 0.6).delay(0.45), value: contentAppeared)
                    }

                    Spacer().frame(height: 28)

                    // 전체 통계
                    let totalFrames = rolls.reduce(0) { $0 + $1.frames.filter { $0.imageData != nil }.count }
                    let totalRolls = rolls.filter(\.isComplete).count
                    HStack(spacing: 0) {
                        statItem(value: "\(totalRolls)", label: "ROLLS")
                        Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 28)
                        statItem(value: "\(totalFrames)", label: "FRAMES")
                        Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 28)
                        statItem(value: totalRolls > 0 ? String(format: "%.1f", Double(totalFrames) / Double(totalRolls)) : "—", label: "AVG")
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: contentAppeared)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 48)

                    // 현재 필름 상태 표시 (있을 때만)
                    if let roll = activeRoll {
                        activeRollBadge(roll: roll)
                            .opacity(contentAppeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.55), value: contentAppeared)
                            .padding(.bottom, 16)
                    }

                    // 버튼 섹션
                    VStack(spacing: 12) {
                        // 주 버튼 — 필름 불러오기 / 계속 찍기
                        Button(action: {
                            if activeRoll != nil {
                                navigateToCamera = true
                            } else {
                                showFilmPicker = true
                            }
                        }) {
                            HStack(spacing: 14) {
                                Image(systemName: activeRoll != nil ? "camera.fill" : "film")
                                    .font(.system(size: 16))
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activeRoll != nil ? "CONTINUE SHOOTING" : "LOAD NEW FILM")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .tracking(1.0)
                                    Text(activeRoll != nil ? "필름이 카메라에 장전되어 있어요" : "새로운 필름을 카메라에 넣어요")
                                        .font(.system(size: 9, weight: .light, design: .monospaced))
                                        .opacity(0.65)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.7)
                            }
                            .foregroundColor(Color(hex: "#1C1209"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#D4891E"), Color(hex: "#C8762A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(hex: "#C8762A").opacity(0.4), radius: 16, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: contentAppeared)

                        // 보조 버튼 — 필름 박스
                        Button(action: { navigateToStorage = true }) {
                            HStack(spacing: 14) {
                                Image(systemName: "archivebox")
                                    .font(.system(size: 16))
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("MY FILM BOX")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .tracking(1.0)
                                    Text(completedCount > 0 ? "\(completedCount)개의 롤이 보관되어 있어요" : "현상된 롤이 보관됩니다")
                                        .font(.system(size: 9, weight: .light, design: .monospaced))
                                        .opacity(0.45)
                                }

                                Spacer(minLength: 8)

                                // 롤 수 배지
                                if completedCount > 0 {
                                    Text("\(completedCount)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(hex: "#C8762A"))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color(hex: "#C8762A").opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .opacity(0.3)
                                }
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6), value: contentAppeared)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    // 하단 감성 문구
                    Text("analog memories in a digital world")
                        .font(.system(size: 9, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.12))
                        .tracking(1)
                        .opacity(contentAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.75), value: contentAppeared)
                        .padding(.bottom, 40)
                }
                .frame(width: geo.size.width)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            logoAppeared = true
            contentAppeared = true
        }
        .fullScreenCover(isPresented: $navigateToCamera) {
            MainView()
        }
        .sheet(isPresented: $navigateToStorage) {
            StorageBoxView()
        }
        .sheet(isPresented: $showFilmPicker, onDismiss: {
            if pendingNavigateToCamera {
                pendingNavigateToCamera = false
                navigateToCamera = true
            }
        }) {
            FilmPickerView(nextRollNumber: (rolls.map(\.number).max() ?? 0) + 1) { stock, frameCount, name in
                loadFilm(stock, frameCount: frameCount, name: name)
                pendingNavigateToCamera = true
            }
        }
    }

    // MARK: - Stat Item

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Active Roll Badge

    private func activeRollBadge(roll: Roll) -> some View {
        HStack(spacing: 10) {
            // 필름 색상 닷
            Circle()
                .fill(roll.filmStock.dimmedCanisterColor)
                .frame(width: 6, height: 6)

            Text("ROLL \(String(format: "%02d", roll.number))")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(roll.filmStock.dimmedCanisterColor.opacity(0.8))
                .tracking(2)

            Text("·")
                .foregroundColor(.white.opacity(0.2))

            Text(roll.filmStock.name.uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1)

            Text("·")
                .foregroundColor(.white.opacity(0.2))

            Text("\(roll.frameCount) / \(roll.frameCountLimit)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(roll.filmStock.dimmedCanisterColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Load Film

    private func loadFilm(_ stock: FilmStock, frameCount: Int, name: String? = nil) {
        let newRoll = Roll(
            number: (rolls.map(\.number).max() ?? 0) + 1,
            filmStockID: stock.id,
            frameCountLimit: frameCount,
            customName: name
        )
        context.insert(newRoll)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Roll.self, Frame.self], inMemory: true)
}
