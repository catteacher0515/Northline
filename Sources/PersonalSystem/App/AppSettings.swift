import AppKit
import Foundation

struct AppSettings: Codable, Equatable {
    var referenceDurationSeconds: Int
    var startEndShortcut: KeyboardShortcut

    static let `default` = AppSettings(
        referenceDurationSeconds: 1_500,
        startEndShortcut: KeyboardShortcut(
            keyCode: 35,
            keyEquivalent: "p",
            modifierFlagsRawValue: KeyboardShortcut.normalizedModifierFlags([.control, .command]).rawValue
        )
    )
}

struct KeyboardShortcut: Codable, Equatable {
    let keyCode: UInt16
    let keyEquivalent: String
    let modifierFlagsRawValue: UInt

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlagsRawValue)
    }

    var displayString: String {
        let flags = modifierFlags
        var parts: [String] = []

        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }

        return parts.joined() + keyEquivalent.uppercased()
    }

    func matches(_ event: NSEvent) -> Bool {
        keyCode == event.keyCode && modifierFlags == Self.normalizedModifierFlags(event.modifierFlags)
    }

    static func from(event: NSEvent) -> KeyboardShortcut? {
        let keyEquivalent = (event.charactersIgnoringModifiers ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard keyEquivalent.isEmpty == false else {
            return nil
        }

        let flags = normalizedModifierFlags(event.modifierFlags)
        guard flags.isEmpty == false else {
            return nil
        }

        return KeyboardShortcut(
            keyCode: event.keyCode,
            keyEquivalent: keyEquivalent,
            modifierFlagsRawValue: flags.rawValue
        )
    }

    static func normalizedModifierFlags(_ flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        flags.intersection([.control, .option, .shift, .command])
    }
}
