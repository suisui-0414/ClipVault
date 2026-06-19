import AppKit
import Combine

@MainActor
final class ClipboardMonitor: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private let store = HistoryStore()
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private var isWritingToPasteboard = false

    init(pollInterval: TimeInterval = 0.5) {
        self.lastChangeCount = pasteboard.changeCount
        self.items = store.load()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkPasteboard() }
        }
    }

    private func checkPasteboard() {
        guard !isWritingToPasteboard else { return }
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard items.first?.text != text else { return }

        var updated = items.filter { $0.text != text }
        updated.insert(ClipboardItem(text: text), at: 0)
        items = Array(updated.prefix(HistoryStore.maxItems))
        store.save(items)
    }

    func copyToPasteboard(_ item: ClipboardItem) {
        isWritingToPasteboard = true
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        lastChangeCount = pasteboard.changeCount
        isWritingToPasteboard = false
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        store.save(items)
    }

    func clearHistory() {
        items = []
        store.save(items)
    }
}
