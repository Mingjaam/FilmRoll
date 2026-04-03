import SwiftUI
import SwiftData

struct StorageBoxView: View {
    @Query(sort: \Roll.number, order: .reverse) private var rolls: [Roll]
    @State private var selectedRoll: Roll?

    var completedRolls: [Roll] {
        rolls.filter { $0.isComplete }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#111111").ignoresSafeArea()

                if completedRolls.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // 헤더
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MY FILM BOX")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(hex: "#C8762A").opacity(0.7))
                                    .tracking(3)

                                Text("\(completedRolls.count) Rolls · \(completedRolls.reduce(0) { $0 + $1.frameCount }) Frames")
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                            // 캐니스터 그리드
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 20) {
                                ForEach(completedRolls) { roll in
                                    CanisterView(roll: roll)
                                        .onTapGesture { selectedRoll = roll }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedRoll) { roll in
                RollDetailView(roll: roll)
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: stock.canisterHex))
                    .frame(width: 56, height: 70)

                VStack(spacing: 5) {
                    // 상단 캡
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: stock.canisterHex).opacity(0.6))
                        .frame(width: 30, height: 8)
                        .offset(y: -28)

                    // 라벨
                    VStack(spacing: 2) {
                        Text(stock.name.uppercased())
                            .font(.system(size: 5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.black.opacity(0.5))
                            .tracking(1)

                        Text(String(format: "%02d", roll.number))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }

            Text(roll.dateRangeLabel)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}
