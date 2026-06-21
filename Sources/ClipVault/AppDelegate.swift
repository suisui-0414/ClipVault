import AppKit
import Carbon.HIToolbox
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor()
    private var statusItem: NSStatusItem!
    private var panel: HistoryPanel!
    private var hotKey: GlobalHotKey?
    private var cancellable: AnyCancellable?
    private var selectedIndex: Int?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if terminateIfAlreadyRunning() { return }

        NSApp.setActivationPolicy(.accessory)
        registerAsLoginItemIfNeeded()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipVault")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(handleStatusItemClick)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        panel = HistoryPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 100))
        panel.onKeyDown = { [weak self] event in
            self?.handleKeyDown(event) ?? false
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(panelResignedKey),
            name: NSWindow.didResignKeyNotification, object: panel
        )
        rebuildPanelContent()

        cancellable = monitor.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                if let index = self.selectedIndex, index >= items.count {
                    self.selectedIndex = items.isEmpty ? nil : items.count - 1
                }
                self.rebuildPanelContent()
            }

        // ⌘⇧V でメニューを開く
        hotKey = GlobalHotKey(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            self?.togglePanel()
        }
    }

    /// 同じバンドルIDのインスタンスが既に起動していれば、自分自身を終了する。
    private func terminateIfAlreadyRunning() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let myPID = ProcessInfo.processInfo.processIdentifier
        let alreadyRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID && $0.processIdentifier != myPID
        }
        guard alreadyRunning else { return false }
        NSApp.terminate(nil)
        return true
    }

    private func registerAsLoginItemIfNeeded() {
        let service = SMAppService.mainApp
        switch service.status {
        case .enabled, .requiresApproval:
            return
        default:
            try? service.register()
        }
    }

    @objc private func handleStatusItemClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "ClipVaultを終了", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        guard let button = statusItem.button else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY), in: button)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func panelResignedKey(_ notification: Notification) {
        closePanel()
    }

    private func showPanel() {
        selectedIndex = monitor.items.isEmpty ? nil : 0
        rebuildPanelContent()

        let mouseLocation = NSEvent.mouseLocation
        let size = panel.frame.size
        var origin = CGPoint(x: mouseLocation.x, y: mouseLocation.y - size.height)

        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            origin.x = min(max(origin.x, frame.minX), max(frame.minX, frame.maxX - size.width))
            origin.y = min(max(origin.y, frame.minY), max(frame.minY, frame.maxY - size.height))
        }

        panel.setFrameOrigin(origin)
        panel.makeKeyAndOrderFront(nil)
    }

    private func closePanel() {
        panel.orderOut(nil)
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        switch Int(event.keyCode) {
        case kVK_DownArrow:
            moveSelection(by: 1)
            return true
        case kVK_UpArrow:
            moveSelection(by: -1)
            return true
        case kVK_Return, kVK_ANSI_KeypadEnter:
            confirmSelection()
            return true
        case kVK_Delete, kVK_ForwardDelete:
            deleteSelected()
            return true
        case kVK_Escape:
            closePanel()
            return true
        default:
            break
        }

        switch event.charactersIgnoringModifiers?.lowercased() {
        case "j":
            moveSelection(by: 1)
            return true
        case "k":
            moveSelection(by: -1)
            return true
        default:
            return false
        }
    }

    private func moveSelection(by delta: Int) {
        guard !monitor.items.isEmpty else { return }
        let current = selectedIndex ?? (delta > 0 ? -1 : monitor.items.count)
        selectedIndex = min(max(current + delta, 0), monitor.items.count - 1)
        rebuildPanelContent()
    }

    private func confirmSelection() {
        guard let index = selectedIndex, monitor.items.indices.contains(index) else { return }
        monitor.copyToPasteboard(monitor.items[index])
        closePanel()
    }

    private func deleteSelected() {
        guard let index = selectedIndex, monitor.items.indices.contains(index) else { return }
        monitor.delete(monitor.items[index])
        selectedIndex = monitor.items.isEmpty ? nil : min(index, monitor.items.count - 1)
        rebuildPanelContent()
    }

    private func rebuildPanelContent() {
        let view = ClipboardHistoryView(
            monitor: monitor,
            selectedIndex: selectedIndex,
            onSelect: { [weak self] item in
                self?.monitor.copyToPasteboard(item)
                self?.closePanel()
            },
            onDelete: { [weak self] item in
                guard let self else { return }
                if let index = self.monitor.items.firstIndex(of: item), self.selectedIndex == index {
                    self.selectedIndex = nil
                }
                self.monitor.delete(item)
            },
            onClear: { [weak self] in self?.monitor.clearHistory() },
            onClose: { [weak self] in self?.closePanel() }
        )
        let hostingView = NSHostingView(rootView: view)
        let fittingSize = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: fittingSize)
        panel.contentView = hostingView
        panel.setContentSize(fittingSize)
    }
}
