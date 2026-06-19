import Foundation

final class HistoryStore {
    static let maxItems = 10

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("ClipVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("history.json")
    }

    func load() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([ClipboardItem].self, from: data)) ?? []
    }

    func save(_ items: [ClipboardItem]) {
        let trimmed = Array(items.prefix(Self.maxItems))
        guard let data = try? JSONEncoder().encode(trimmed) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
