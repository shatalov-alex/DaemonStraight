//
//  SettingsManager.swift
//  DaemonStraight
//
//  Settings manager for storing and retrieving user preferences
//

import Cocoa

class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        // Mouse highlighting
        static let mouseDefaultColor = "mouseDefaultColor"
        static let mouseLeftClickColor = "mouseLeftClickColor"
        static let mouseRightClickColor = "mouseRightClickColor"
        static let mouseDiameter = "mouseDiameter"
        static let mouseWidth = "mouseWidth"

        // Drawing
        static let drawingColor = "drawingColor"
        static let drawingWidth = "drawingWidth"

        // Keyboard display filter
        static let showModifierKeys = "showModifierKeys"
        static let showFunctionKeys = "showFunctionKeys"
        static let showAlphanumericKeys = "showAlphanumericKeys"
        static let showSpecialKeys = "showSpecialKeys"

        // Hotkeys
        static let mouseToggleHotkey = "mouseToggleHotkey"
        static let keyboardToggleHotkey = "keyboardToggleHotkey"
        static let drawingToggleHotkey = "drawingToggleHotkey"
    }

    // MARK: - Mouse Highlighting Settings
    var mouseDefaultColor: NSColor {
        get { colorForKey(Keys.mouseDefaultColor) ?? NSColor.systemBlue }
        set { setColor(newValue, forKey: Keys.mouseDefaultColor) }
    }

    var mouseLeftClickColor: NSColor {
        get { colorForKey(Keys.mouseLeftClickColor) ?? NSColor.systemGreen }
        set { setColor(newValue, forKey: Keys.mouseLeftClickColor) }
    }

    var mouseRightClickColor: NSColor {
        get { colorForKey(Keys.mouseRightClickColor) ?? NSColor.systemPurple }
        set { setColor(newValue, forKey: Keys.mouseRightClickColor) }
    }

    var mouseDiameter: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.mouseDiameter)) > 0 ? CGFloat(defaults.double(forKey: Keys.mouseDiameter)) : 100.0 }
        set { defaults.set(Double(newValue), forKey: Keys.mouseDiameter) }
    }

    var mouseWidth: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.mouseWidth)) > 0 ? CGFloat(defaults.double(forKey: Keys.mouseWidth)) : 7.0 }
        set { defaults.set(Double(newValue), forKey: Keys.mouseWidth) }
    }

    // MARK: - Drawing Settings
    var drawingColor: NSColor {
        get { colorForKey(Keys.drawingColor) ?? NSColor.red }
        set { setColor(newValue, forKey: Keys.drawingColor) }
    }

    var drawingWidth: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.drawingWidth)) > 0 ? CGFloat(defaults.double(forKey: Keys.drawingWidth)) : 5.0 }
        set { defaults.set(Double(newValue), forKey: Keys.drawingWidth) }
    }

    // MARK: - Keyboard Display Filter
    var showModifierKeys: Bool {
        get { defaults.object(forKey: Keys.showModifierKeys) == nil ? true : defaults.bool(forKey: Keys.showModifierKeys) }
        set { defaults.set(newValue, forKey: Keys.showModifierKeys) }
    }

    var showFunctionKeys: Bool {
        get { defaults.object(forKey: Keys.showFunctionKeys) == nil ? true : defaults.bool(forKey: Keys.showFunctionKeys) }
        set { defaults.set(newValue, forKey: Keys.showFunctionKeys) }
    }

    // Plain typing (letters/digits without ⌘⌥⌃fn). Off by default - originally never shown
    var showAlphanumericKeys: Bool {
        get { defaults.object(forKey: Keys.showAlphanumericKeys) == nil ? false : defaults.bool(forKey: Keys.showAlphanumericKeys) }
        set { defaults.set(newValue, forKey: Keys.showAlphanumericKeys) }
    }

    var showSpecialKeys: Bool {
        get { defaults.object(forKey: Keys.showSpecialKeys) == nil ? true : defaults.bool(forKey: Keys.showSpecialKeys) }
        set { defaults.set(newValue, forKey: Keys.showSpecialKeys) }
    }

    // MARK: - Hotkeys
    struct Hotkey: Codable {
        let keyCode: UInt16
        let modifiers: UInt

        var description: String {
            var parts: [String] = []
            let flags = NSEvent.ModifierFlags(rawValue: modifiers)

            if flags.contains(.control) { parts.append("⌃") }
            if flags.contains(.option) { parts.append("⌥") }
            if flags.contains(.command) { parts.append("⌘") }
            if flags.contains(.shift) { parts.append("⇧") }

            // Convert keyCode to character
            let key = keyCodeToString(keyCode)
            parts.append(key.uppercased())

            return parts.joined()
        }

        private func keyCodeToString(_ keyCode: UInt16) -> String {
            switch keyCode {
            case 0: return "A"
            case 1: return "S"
            case 2: return "D"
            case 3: return "F"
            case 4: return "H"
            case 5: return "G"
            case 6: return "Z"
            case 7: return "X"
            case 8: return "C"
            case 9: return "V"
            case 11: return "B"
            case 12: return "Q"
            case 13: return "W"
            case 14: return "E"
            case 15: return "R"
            case 16: return "Y"
            case 17: return "T"
            case 31: return "O"
            case 32: return "U"
            case 34: return "I"
            case 35: return "P"
            case 37: return "L"
            case 38: return "J"
            case 40: return "K"
            case 45: return "N"
            case 46: return "M"
            case 18: return "1"
            case 19: return "2"
            case 20: return "3"
            case 21: return "4"
            case 23: return "5"
            case 22: return "6"
            case 26: return "7"
            case 28: return "8"
            case 25: return "9"
            case 29: return "0"
            case 122: return "F1"
            case 120: return "F2"
            case 99: return "F3"
            case 118: return "F4"
            case 96: return "F5"
            case 97: return "F6"
            case 98: return "F7"
            case 100: return "F8"
            case 101: return "F9"
            case 109: return "F10"
            case 103: return "F11"
            case 111: return "F12"
            case 123: return "←"
            case 124: return "→"
            case 125: return "↓"
            case 126: return "↑"
            default: return "?"
            }
        }
    }

    var mouseToggleHotkey: Hotkey {
        get {
            if let data = defaults.data(forKey: Keys.mouseToggleHotkey),
               let hotkey = try? JSONDecoder().decode(Hotkey.self, from: data) {
                return hotkey
            }
            // Default: ⌃⌥⌘M
            return Hotkey(keyCode: 46, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue)
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.mouseToggleHotkey)
            }
        }
    }

    var keyboardToggleHotkey: Hotkey {
        get {
            if let data = defaults.data(forKey: Keys.keyboardToggleHotkey),
               let hotkey = try? JSONDecoder().decode(Hotkey.self, from: data) {
                return hotkey
            }
            // Default: ⌃⌥⌘K
            return Hotkey(keyCode: 40, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue)
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.keyboardToggleHotkey)
            }
        }
    }

    var drawingToggleHotkey: Hotkey {
        get {
            if let data = defaults.data(forKey: Keys.drawingToggleHotkey),
               let hotkey = try? JSONDecoder().decode(Hotkey.self, from: data) {
                return hotkey
            }
            // Default: ⌃⌥⌘D
            return Hotkey(keyCode: 2, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue)
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.drawingToggleHotkey)
            }
        }
    }

    // MARK: - Helper Methods
    private func colorForKey(_ key: String) -> NSColor? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
    }

    private func setColor(_ color: NSColor, forKey key: String) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            defaults.set(data, forKey: key)
        }
    }

    func resetToDefaults() {
        // Remove all settings
        defaults.removeObject(forKey: Keys.mouseDefaultColor)
        defaults.removeObject(forKey: Keys.mouseLeftClickColor)
        defaults.removeObject(forKey: Keys.mouseRightClickColor)
        defaults.removeObject(forKey: Keys.mouseDiameter)
        defaults.removeObject(forKey: Keys.mouseWidth)
        defaults.removeObject(forKey: Keys.drawingColor)
        defaults.removeObject(forKey: Keys.drawingWidth)
        defaults.removeObject(forKey: Keys.showModifierKeys)
        defaults.removeObject(forKey: Keys.showFunctionKeys)
        defaults.removeObject(forKey: Keys.showAlphanumericKeys)
        defaults.removeObject(forKey: Keys.showSpecialKeys)
        defaults.removeObject(forKey: Keys.mouseToggleHotkey)
        defaults.removeObject(forKey: Keys.keyboardToggleHotkey)
        defaults.removeObject(forKey: Keys.drawingToggleHotkey)
    }
}
