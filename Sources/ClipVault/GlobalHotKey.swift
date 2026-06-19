import Carbon.HIToolbox
import Foundation

final class GlobalHotKey {
    private static var eventHandler: EventHandlerRef?
    private static var registry: [UInt32: () -> Void] = [:]
    private static var nextID: UInt32 = 1
    private static let signature: OSType = 0x434C5056 // "CLPV"

    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID: UInt32

    init?(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        Self.installHandlerIfNeeded()

        let id = Self.nextID
        Self.nextID += 1
        Self.registry[id] = handler
        hotKeyID = id

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            EventHotKeyID(signature: Self.signature, id: id),
            GetEventDispatcherTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else {
            Self.registry[id] = nil
            return nil
        }
        hotKeyRef = ref
    }

    private static func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetEventDispatcherTarget(), { _, eventRef, _ -> OSStatus in
            guard let eventRef else { return noErr }
            var hkID = EventHotKeyID()
            GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hkID
            )
            let id = hkID.id
            DispatchQueue.main.async {
                GlobalHotKey.registry[id]?()
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        Self.registry[hotKeyID] = nil
    }

    deinit {
        unregister()
    }
}
