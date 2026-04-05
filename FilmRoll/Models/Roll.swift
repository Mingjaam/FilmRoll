import Foundation
import SwiftData

@Model
class Roll {
    var id: UUID
    var number: Int
    var filmStockID: String?   // optional for backward compat with existing data
    var frameCountLimit: Int   // 필수: 선택한 장수
    var customCanisterHex: String?
    var startDate: Date
    var endDate: Date?
    var isComplete: Bool
    @Relationship(deleteRule: .cascade) var frames: [Frame]

    var filmStock: FilmStock {
        guard let id = filmStockID else { return .solaris }
        return FilmStock.all.first(where: { $0.id == id }) ?? .solaris
    }

    var frameCount: Int { frames.count }
    var isFull: Bool { frames.count >= frameCountLimit }

    var dateRangeLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM dd"
        let start = fmt.string(from: startDate)
        if let end = endDate {
            return "\(start) - \(fmt.string(from: end))"
        }
        return "\(start) - "
    }

    var sortedFrames: [Frame] {
        frames.sorted { $0.orderIndex < $1.orderIndex }
    }

    init(number: Int, filmStockID: String, frameCountLimit: Int, customCanisterHex: String? = nil) {
        self.id = UUID()
        self.number = number
        self.filmStockID = filmStockID
        self.frameCountLimit = frameCountLimit
        self.customCanisterHex = customCanisterHex
        self.startDate = .now
        self.endDate = nil
        self.isComplete = false
        self.frames = []
    }
}
