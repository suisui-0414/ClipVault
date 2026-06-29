import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var monitor: ClipboardMonitor
    var selectedIndex: Int?
    var onSelect: (ClipboardItem) -> Void
    var onDelete: (ClipboardItem) -> Void
    var onClear: () -> Void
    var onClose: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    private let listHeight: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if monitor.items.isEmpty {
                    VStack {
                        Spacer()
                        Text("履歴はありません")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(monitor.items.enumerated()), id: \.element.id) { index, item in
                                    rowButton(item, isSelected: index == selectedIndex)
                                        .id(index)
                                }
                            }
                        }
                        .onChange(of: selectedIndex) { newValue in
                            guard let newValue else { return }
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
            .frame(height: listHeight)

            if !monitor.items.isEmpty {
                Divider()
                footerButton("履歴をクリア", action: onClear)
            }
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
