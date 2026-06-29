import Foundation

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let copiedAt: Date

    init(text: String, copiedAt: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.copiedAt = copiedAt
    }
}
