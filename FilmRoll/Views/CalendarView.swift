import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var rolls: [Roll]
    @Environment(\.dismiss) private var dismiss

    @State private var currentDate = Date()

    private let calendar = Calendar.current
    private let dayNames = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    // MARK: - Computed

    private var displayYear: Int { calendar.component(.year, from: currentDate) }
    private var displayMonth: Int { calendar.component(.month, from: currentDate) }

    // 현재 월의 날짜별 촬영 장수
    private var framesByDay: [Int: Int] {
        var dict: [Int: Int] = [:]
        for roll in rolls {
            for frame in roll.frames where frame.imageData != nil {
                let comp = calendar.dateComponents([.year, .month, .day], from: frame.capturedAt)
                guard comp.year == displayYear, comp.month == displayMonth,
                      let day = comp.day else { continue }
                dict[day, default: 0] += 1
            }
        }
        return dict
    }

    private var daysInMonth: Int {
        let comps = DateComponents(year: displayYear, month: displayMonth)
        guard let date = calendar.date(from: comps) else { return 30 }
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    // 첫 날의 요일 오프셋 (0=일요일)
    private var firstWeekdayOffset: Int {
        let comps = DateComponents(year: displayYear, month: displayMonth, day: 1)
        guard let date = calendar.date(from: comps) else { return 0 }
        return calendar.component(.weekday, from: date) - 1
    }

    private var monthTotalFrames: Int {
        framesByDay.values.reduce(0, +)
    }

    private var monthActiveDays: Int {
        framesByDay.keys.count
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy  MMM"
        return f.string(from: currentDate).uppercased()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hex: "#111111").ignoresSafeArea()

            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex: "#C8762A"))
                    }
                    Spacer()
                    Text("SHOOTING LOG")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(3)
                    Spacer()
                    Color.clear.frame(width: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // 월 네비게이션
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.6))
                            .frame(width: 36, height: 36)
                    }

                    Spacer()

                    Text(monthLabel)
                        .font(.system(size: 16, weight: .light, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)

                    Spacer()

                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.6))
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

                // 요일 레이블
                HStack(spacing: 0) {
                    ForEach(dayNames, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.25))
                            .tracking(1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

                // 캘린더 그리드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                    // 첫 날 전 빈 셀
                    ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                        Color.clear.frame(height: 48)
                    }

                    // 날짜 셀
                    ForEach(1...daysInMonth, id: \.self) { day in
                        DayCell(day: day, count: framesByDay[day] ?? 0,
                                isToday: isToday(day: day))
                    }
                }
                .padding(.horizontal, 8)

                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)

                // 월간 통계
                HStack(spacing: 0) {
                    statItem(value: "\(monthTotalFrames)", label: "FRAMES")
                    Divider().frame(width: 1, height: 36)
                        .background(Color.white.opacity(0.1))
                    statItem(value: "\(monthActiveDays)", label: "DAYS")
                    Divider().frame(width: 1, height: 36)
                        .background(Color.white.opacity(0.1))
                    statItem(value: monthActiveDays > 0 ? String(format: "%.1f", Double(monthTotalFrames) / Double(monthActiveDays)) : "—",
                             label: "AVG/DAY")
                }
                .padding(.horizontal, 24)

                Spacer()

                // 전체 통계
                let totalFrames = rolls.reduce(0) { $0 + $1.frames.filter { $0.imageData != nil }.count }
                let totalRolls = rolls.filter(\.isComplete).count

                VStack(spacing: 4) {
                    Text("ALL TIME · \(totalFrames) FRAMES · \(totalRolls) ROLLS")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.2))
                        .tracking(2)
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Helpers

    private func isToday(day: Int) -> Bool {
        let todayComps = calendar.dateComponents([.year, .month, .day], from: Date())
        return todayComps.year == displayYear && todayComps.month == displayMonth && todayComps.day == day
    }

    private func previousMonth() {
        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
    }

    private func nextMonth() {
        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
    }

    @ViewBuilder
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .light, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let day: Int
    let count: Int
    let isToday: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text("\(day)")
                .font(.system(size: 13, weight: isToday ? .medium : .light, design: .monospaced))
                .foregroundColor(isToday ? Color(hex: "#C8762A") : (count > 0 ? .white : .white.opacity(0.3)))

            // 촬영 수 인디케이터
            if count > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(count, 5), id: \.self) { _ in
                        Circle()
                            .fill(Color(hex: "#C8762A").opacity(0.7))
                            .frame(width: 3, height: 3)
                    }
                    if count > 5 {
                        Text("+")
                            .font(.system(size: 5, design: .monospaced))
                            .foregroundColor(Color(hex: "#C8762A").opacity(0.5))
                    }
                }
            } else {
                Color.clear.frame(height: 5)
            }
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(count > 0 ? Color.white.opacity(0.04) : Color.clear)
        )
    }
}
