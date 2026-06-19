import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var monitor: ClipboardMonitor
    var selectedIndex: Int?
    var onSelect: (ClipboardItem) -> Void
    var onDelete: (ClipboardItem) -> Void
    var onClear: () -> Void
    var onQuit: () -> Void
    var onClose: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if monitor.items.isEmpty {
                Text("履歴はありません")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(monitor.items.enumerated()), id: \.element.id) { index, item in
                    rowButton(item, isSelected: index == selectedIndex)
                }
                Divider()
                footerButton("履歴をクリア", action: onClear)
            }
            Divider()
            footerButton("終了", action: onQuit)
        }
        .padding(.vertical, 6)
        .frame(width: 300)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onExitCommand(perform: onClose)
    }

    private func rowButton(_ item: ClipboardItem, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                onSelect(item)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(oneLine(item.text))
                        .lineLimit(1)
                    Text(Self.dateFormatter.string(from: item.copiedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onDelete(item)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
    }

    private func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func oneLine(_ text: String) -> String {
        let oneLine = text.replacingOccurrences(of: "\n", with: " ")
        return oneLine.count > 40 ? String(oneLine.prefix(40)) + "…" : oneLine
    }
}
