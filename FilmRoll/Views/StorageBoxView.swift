import SwiftUI
import SwiftData

struct StorageBoxView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Roll.number, order: .reverse) private var rolls: [Roll]
    @State private var selectedRoll: Roll?
    @State private var showCalendar = false
    @State private var rollToDelete: Roll?
    @State private var showDeleteConfirm = false

    var completedRolls: [Roll] {
        rolls.filter { $0.isComplete }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#111111").ignoresSafeArea()

                VStack(spacing: 0) {
                    // 항상 표시되는 헤더
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MY FILM BOX")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                                .tracking(3)
                            Text("\(completedRolls.count) Rolls · \(completedRolls.reduce(0) { $0 + $1.frameCount }) Frames")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: { showCalendar = true }) {
                            VStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                                Text("LOG")
                                    .font(.system(size: 7, design: .monospaced))
                                    .foregroundColor(Color(hex: "#C8762A").opacity(0.4))
                                    .tracking(1)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    if completedRolls.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 32) {
                                ForEach(completedRolls) { roll in
                                    CanisterView(roll: roll)
                                        .onTapGesture { selectedRoll = roll }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                rollToDelete = roll
                                                showDeleteConfirm = true
                                            } label: {
                                                Label("이 롤을 버릴게요", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 52)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedRoll) { roll in
                RollDetailView(roll: roll)
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView()
            }
            .alert("이 필름을 버릴까요?", isPresented: $showDeleteConfirm, presenting: rollToDelete) { roll in
                Button("아직은 간직할게요", role: .cancel) { }
                Button("보내줄게요", role: .destructive) {
                    context.delete(roll)
                }
            } message: { roll in
                Text("ROLL \(String(format: "%02d", roll.number))에 담긴 \(roll.frameCount)장의 기억이 사라져요.\n한번 떠나면 다시 돌아오지 않아요.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("FILM BOX")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                .tracking(3)

            Text("완성된 롤이 없어요")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white.opacity(0.3))

            Text("필름을 다 채우면\n여기에 보관됩니다")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.2))
                .multilineTextAlignment(.center)
        }
    }
}

struct CanisterView: View {
    let roll: Roll

    private var stock: FilmStock { roll.filmStock }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 캐니스터 몸통
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(stock.dimmedCanisterColor)
                        .frame(width: 56, height: 70)
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: 56, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(spacing: 2) {
                        Text(stock.name.uppercased())
                            .font(.system(size: 5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.black.opacity(0.45))
                            .tracking(1)
                        Text(String(format: "%02d", roll.number))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.black.opacity(0.65))
                    }
                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                    // 상단 캡
                    RoundedRectangle(cornerRadius: 3)
                        .fill(stock.dimmedCanisterColor)
                        .brightness(0.2)
                        .frame(width: 30, height: 9)
                        .offset(y: -37)
                }

                // 프레임 수 배지
                VStack {
                    HStack {
                        Spacer()
                        Text("\(roll.frameCount)")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#1C1209"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(stock.dimmedCanisterColor)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    Spacer()
                }
                .frame(width: 56)
            }

            Text(roll.dateRangeLabel)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}
