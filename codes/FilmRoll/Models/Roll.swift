import Foundation
import SwiftData

@Model
class Roll {
    var id: UUID
    var number: Int
    var startDate: Date
    var endDate: Date?
    var isComplete: Bool
    @Relationship(deleteRule: .cascade) var frames: [Frame]

    var frameCount: Int { frames.count }
    var isFull: Bool { frames.count >= 36 }

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

    init(number: Int) {
        self.id = UUID()
        self.number = number
        self.startDate = .now
        self.endDate = nil
        self.isComplete = false
        self.frames = []
    }
}
