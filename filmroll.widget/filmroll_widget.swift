import WidgetKit
import SwiftUI

// MARK: - Data

private let appGroupID = "group.com.filmroll"

struct RollEntry: TimelineEntry {
    let date: Date
    let rollNumber: Int
    let filmName: String
    let canisterHex: String
    let frameCount: Int
    let totalFrames: Int
}

extension RollEntry {
    static var placeholder: RollEntry {
        RollEntry(date: .now, rollNumber: 1, filmName: "Solaris", canisterHex: "#C8900A",
                  frameCount: 12, totalFrames: 36)
    }
    static var empty: RollEntry {
        RollEntry(date: .now, rollNumber: 0, filmName: "", canisterHex: "#555555",
                  frameCount: 0, totalFrames: 36)
    }
}

// MARK: - Provider

struct RollProvider: TimelineProvider {
    func placeholder(in context: Context) -> RollEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (RollEntry) -> Void) {
        completion(context.isPreview ? .placeholder : readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RollEntry>) -> Void) {
        let entry = readEntry()
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func readEntry() -> RollEntry {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let rollNumber = defaults.integer(forKey: "filmroll.rollNumber")
        let filmName   = defaults.string(forKey: "filmroll.filmName")   ?? ""
        let hex        = defaults.string(forKey: "filmroll.canisterHex") ?? "#555555"
        let frameCount = defaults.integer(forKey: "filmroll.frameCount")
        let total      = defaults.integer(forKey: "filmroll.totalFrames")

        guard rollNumber > 0 else { return .empty }
        return RollEntry(date: .now, rollNumber: rollNumber, filmName: filmName,
                         canisterHex: hex, frameCount: frameCount, totalFrames: max(1, total))
    }
}

// MARK: - Color Helper

extension Color {
    init(widgetHex hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget Entry View

struct filmroll_widgetEntryView: View {
    var entry: RollEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .systemMedium {
                MediumWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            Color(widgetHex: "#111111")
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: RollEntry

    private var progress: Double {
        guard entry.totalFrames > 0 else { return 0 }
        return min(1.0, Double(entry.frameCount) / Double(entry.totalFrames))
    }

    var body: some View {
        if entry.rollNumber == 0 {
            VStack(spacing: 6) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.2))
                Text("NO FILM")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(2)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.filmName.uppercased())
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(widgetHex: entry.canisterHex))
                    .tracking(2)
                    .lineLimit(1)

                Spacer()

                Text("ROLL \(String(format: "%02d", entry.rollNumber))")
                    .font(.system(size: 9, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(entry.frameCount)")
                        .font(.system(size: 32, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                    Text("/ \(entry.totalFrames)")
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                WidgetProgressBar(progress: progress, tintHex: entry.canisterHex)
            }
            .padding(14)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: RollEntry

    private var progress: Double {
        guard entry.totalFrames > 0 else { return 0 }
        return min(1.0, Double(entry.frameCount) / Double(entry.totalFrames))
    }

    var body: some View {
        if entry.rollNumber == 0 {
            VStack(spacing: 6) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.2))
                Text("NO FILM LOADED")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(2)
            }
        } else {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.filmName.uppercased())
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(widgetHex: entry.canisterHex))
                        .tracking(2)
                        .lineLimit(1)

                    Spacer()

                    Text("ROLL \(String(format: "%02d", entry.rollNumber))")
                        .font(.system(size: 9, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(entry.frameCount)")
                            .font(.system(size: 36, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                        Text("/ \(entry.totalFrames)")
                            .font(.system(size: 12, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    WidgetProgressBar(progress: progress, tintHex: entry.canisterHex)
                }

                WidgetMiniGrid(frameCount: entry.frameCount, total: entry.totalFrames,
                               tintHex: entry.canisterHex)
                    .frame(maxWidth: 90)
            }
            .padding(14)
        }
    }
}

// MARK: - Progress Bar (GeometryReader-free)

struct WidgetProgressBar: View {
    let progress: Double
    let tintHex: String

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(height: 3)
            Capsule()
                .fill(Color(widgetHex: tintHex))
                .frame(height: 3)
                .scaleEffect(x: max(0.01, progress), anchor: .leading)
        }
    }
}

// MARK: - Mini Frame Grid

struct WidgetMiniGrid: View {
    let frameCount: Int
    let total: Int
    let tintHex: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<min(total, 36), id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < frameCount
                          ? Color(widgetHex: tintHex).opacity(0.85)
                          : Color.white.opacity(0.08))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

// MARK: - Widget Configuration

struct filmroll_widget: Widget {
    let kind: String = "filmroll_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RollProvider()) { entry in
            filmroll_widgetEntryView(entry: entry)
        }
        .configurationDisplayName("FilmRoll")
        .description("현재 롤 진행도")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    filmroll_widget()
} timeline: {
    RollEntry.placeholder
    RollEntry.empty
}

#Preview(as: .systemMedium) {
    filmroll_widget()
} timeline: {
    RollEntry.placeholder
}
