import Foundation
import SwiftData

@Model
class Frame {
    var id: UUID
    var imageData: Data?
    var capturedAt: Date
    var orderIndex: Int
    var memo: String

    init(imageData: Data? = nil, capturedAt: Date = .now, orderIndex: Int, memo: String = "") {
        self.id = UUID()
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.orderIndex = orderIndex
        self.memo = memo
    }
}
