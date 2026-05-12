//
//  HotKeyManager.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import AppKit
import Carbon
import Combine
import Foundation

struct HotKey: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    static let defaultOpenWindow = HotKey(
        keyCode: 9,
        modifiers: UInt32(cmdKey | shiftKey)
    )

    var displayString: String {
        let modifierString = Self.modifierSymbols(for: modifiers)
        let keyString = Self.keyName(for: keyCode)
        return modifierString + keyString
    }

    var isValid: Bool {
        modifiers != 0
    }

    static func from(event: NSEvent) -> HotKey? {
        let relevantModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let carbonModifiers = carbonModifiers(from: relevantModifiers)
        let hotKey = HotKey(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
        return hotKey.isValid ? hotKey : nil
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0

        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }

        return modifiers
    }

    private static func modifierSymbols(for modifiers: UInt32) -> String {
        var symbols = ""

        if modifiers & UInt32(controlKey) != 0 { symbols += "^" }
        if modifiers & UInt32(optionKey) != 0 { symbols += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { symbols += "⌘" }

        return symbols
    }

    private static func keyName(for keyCode: UInt32) -> String {
        if let mapped = keyCodeMap[keyCode] {
            return mapped
        }

        return "Key \(keyCode)"
    }

    private static let keyCodeMap: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
        38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
        45: "N", 46: "M", 47: ".", 49: "Space", 50: "`", 51: "Delete",
        53: "Esc", 65: ".", 67: "*", 69: "+", 71: "Clear", 75: "/", 76: "Enter",
        78: "-", 81: "=", 82: "0", 83: "1", 84: "2", 85: "3", 86: "4",
        87: "5", 88: "6", 89: "7", 91: "8", 92: "9", 96: "F5", 97: "F6",
        98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13",
        106: "F16", 107: "F14", 109: "F10", 111: "F12", 113: "F15", 114: "Help",
        115: "Home", 116: "PgUp", 117: "Delete", 118: "F4", 119: "End",
        120: "F2", 121: "PgDn", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑"
    ]
}

@MainActor
final class HotKeyManager {
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var hotKeyObserver: AnyCancellable?

    init(preferences: AppPreferences) {
        installEventHandler()
        updateRegistration(for: preferences.hotKey)

        hotKeyObserver = preferences.$hotKey.sink { [weak self] hotKey in
            self?.updateRegistration(for: hotKey)
        }
    }

    deinit {
        Self.unregisterHotKey(&hotKeyRef)

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return noErr
                }

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.onTrigger?()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    private func updateRegistration(for hotKey: HotKey?) {
        unregisterHotKey()

        guard let hotKey, hotKey.isValid else {
            return
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x434C4950), id: 1)
        RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func unregisterHotKey() {
        Self.unregisterHotKey(&hotKeyRef)
    }

    nonisolated private static func unregisterHotKey(_ hotKeyRef: inout EventHotKeyRef?) {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
