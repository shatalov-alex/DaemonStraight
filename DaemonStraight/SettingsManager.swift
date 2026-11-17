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
        static let showModifierClicks = "showModifierClicks"
        static let shortcutPosition = "shortcutPosition"
        static let shortcutKeySize = "shortcutKeySize"

        // Spotlight
        static let spotlightDiameter = "spotlightDiameter"
        static let spotlightDimOpacity = "spotlightDimOpacity"

        // Zoom
        static let zoomDiameter = "zoomDiameter"
        static let zoomMagnification = "zoomMagnification"
        static let hasAskedForScreenRecording = "hasAskedForScreenRecording"

        // Features turned on at launch
        static let launchWithMouse = "launchWithMouse"
        static let launchWithKeyboard = "launchWithKeyboard"
        static let launchWithDrawing = "launchWithDrawing"
        static let launchWithSpotlight = "launchWithSpotlight"

        // Updates
        static let checkForUpdatesAtLaunch = "checkForUpdatesAtLaunch"

        // Hotkeys
        static let mouseToggleHotkey = "mouseToggleHotkey"
        static let keyboardToggleHotkey = "keyboardToggleHotkey"
        static let drawingToggleHotkey = "drawingToggleHotkey"
        static let spotlightToggleHotkey = "spotlightToggleHotkey"
        static let zoomToggleHotkey = "zoomToggleHotkey"
        static let allToggleHotkey = "allToggleHotkey"
        static let undoDrawingHotkey = "undoDrawingHotkey"
        static let nextDrawingColorHotkey = "nextDrawingColorHotkey"
        static let zoomInHotkey = "zoomInHotkey"
        static let zoomOutHotkey = "zoomOutHotkey"
        static let lensLargerHotkey = "lensLargerHotkey"
        static let lensSmallerHotkey = "lensSmallerHotkey"
        static let rememberDrawingColor = "rememberDrawingColor"
        static let paletteColors = "paletteColors"
        static let paletteColorCount = "paletteColorCount"

        // Animation durations
        static let clickAnimationDuration = "clickAnimationDuration"
        static let ringFadeDuration = "ringFadeDuration"
        static let keycapDisplayTime = "keycapDisplayTime"
        static let keycapAnimationDuration = "keycapAnimationDuration"
        static let drawingHoldTime = "drawingHoldTime"
        static let drawingFadeDuration = "drawingFadeDuration"
    }

    // Screen corner where pressed shortcuts are shown
    enum ShortcutPosition: Int, CaseIterable {
        case bottomLeft, bottomRight, topLeft, topRight

        var title: String {
            switch self {
            case .bottomLeft: return "Bottom Left"
            case .bottomRight: return "Bottom Right"
            case .topLeft: return "Top Left"
            case .topRight: return "Top Right"
            }
        }

        var isLeft: Bool { self == .bottomLeft || self == .topLeft }
        var isTop: Bool { self == .topLeft || self == .topRight }
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

    // Modifier + mouse click combinations (e.g. ⌘ Click); plain clicks are never shown
    var showModifierClicks: Bool {
        get { defaults.object(forKey: Keys.showModifierClicks) == nil ? true : defaults.bool(forKey: Keys.showModifierClicks) }
        set { defaults.set(newValue, forKey: Keys.showModifierClicks) }
    }

    var shortcutPosition: ShortcutPosition {
        get { ShortcutPosition(rawValue: defaults.integer(forKey: Keys.shortcutPosition)) ?? .bottomLeft }
        set { defaults.set(newValue.rawValue, forKey: Keys.shortcutPosition) }
    }

    var shortcutKeySize: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.shortcutKeySize)) > 0 ? CGFloat(defaults.double(forKey: Keys.shortcutKeySize)) : 70.0 }
        set { defaults.set(Double(newValue), forKey: Keys.shortcutKeySize) }
    }

    // MARK: - Spotlight Settings
    var spotlightDiameter: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.spotlightDiameter)) > 0 ? CGFloat(defaults.double(forKey: Keys.spotlightDiameter)) : 300.0 }
        set { defaults.set(Double(newValue), forKey: Keys.spotlightDiameter) }
    }

    // Opacity of the dimmed area, 0...1
    var spotlightDimOpacity: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.spotlightDimOpacity)) > 0 ? CGFloat(defaults.double(forKey: Keys.spotlightDimOpacity)) : 0.6 }
        set { defaults.set(Double(newValue), forKey: Keys.spotlightDimOpacity) }
    }

    // MARK: - Zoom Settings
    var zoomDiameter: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.zoomDiameter)) > 0 ? CGFloat(defaults.double(forKey: Keys.zoomDiameter)) : 300.0 }
        set { defaults.set(Double(newValue), forKey: Keys.zoomDiameter) }
    }

    // How many times the lens enlarges the screen
    var zoomMagnification: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.zoomMagnification)) >= 1 ? CGFloat(defaults.double(forKey: Keys.zoomMagnification)) : 2.0 }
        set { defaults.set(Double(newValue), forKey: Keys.zoomMagnification) }
    }

    // macOS shows its Screen Recording prompt only once; later the app opens System Settings instead
    var hasAskedForScreenRecording: Bool {
        get { defaults.bool(forKey: Keys.hasAskedForScreenRecording) }
        set { defaults.set(newValue, forKey: Keys.hasAskedForScreenRecording) }
    }

    // MARK: - Launch Settings (all features are off at launch by default)
    var launchWithMouse: Bool {
        get { defaults.bool(forKey: Keys.launchWithMouse) }
        set { defaults.set(newValue, forKey: Keys.launchWithMouse) }
    }

    var launchWithKeyboard: Bool {
        get { defaults.bool(forKey: Keys.launchWithKeyboard) }
        set { defaults.set(newValue, forKey: Keys.launchWithKeyboard) }
    }

    var launchWithDrawing: Bool {
        get { defaults.bool(forKey: Keys.launchWithDrawing) }
        set { defaults.set(newValue, forKey: Keys.launchWithDrawing) }
    }

    // Off until the user agrees: the app doesn't connect to the network without permission
    var checkForUpdatesAtLaunch: Bool {
        get { defaults.bool(forKey: Keys.checkForUpdatesAtLaunch) }
        set { defaults.set(newValue, forKey: Keys.checkForUpdatesAtLaunch) }
    }

    var hasChosenUpdateChecks: Bool {
        return defaults.object(forKey: Keys.checkForUpdatesAtLaunch) != nil
    }

    var launchWithSpotlight: Bool {
        get { defaults.bool(forKey: Keys.launchWithSpotlight) }
        set { defaults.set(newValue, forKey: Keys.launchWithSpotlight) }
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
            case 24: return "="
            case 27: return "-"
            case 30: return "]"
            case 33: return "["
            case 39: return "'"
            case 41: return ";"
            case 42: return "\\"
            case 43: return ","
            case 44: return "/"
            case 47: return "."
            case 50: return "`"
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

    var spotlightToggleHotkey: Hotkey {
        // Default: ⌃⌥⌘S
        get { hotkey(forKey: Keys.spotlightToggleHotkey) ?? Hotkey(keyCode: 1, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.spotlightToggleHotkey) }
    }

    var zoomToggleHotkey: Hotkey {
        // Default: ⌃⌥⌘Z
        get { hotkey(forKey: Keys.zoomToggleHotkey) ?? Hotkey(keyCode: 6, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.zoomToggleHotkey) }
    }

    var allToggleHotkey: Hotkey {
        // Default: ⌃⌥⌘A
        get { hotkey(forKey: Keys.allToggleHotkey) ?? Hotkey(keyCode: 0, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.allToggleHotkey) }
    }

    // MARK: - Helper Methods
    // ⌃⌥⌘U
    var undoDrawingHotkey: Hotkey {
        get { hotkey(forKey: Keys.undoDrawingHotkey) ?? Hotkey(keyCode: 32, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.undoDrawingHotkey) }
    }

    // ⌃⌥⌘C
    var nextDrawingColorHotkey: Hotkey {
        get { hotkey(forKey: Keys.nextDrawingColorHotkey) ?? Hotkey(keyCode: 8, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.nextDrawingColorHotkey) }
    }

    // ⌃⌥⌘= : zoom in, or a larger spotlight when Zoom is off
    var zoomInHotkey: Hotkey {
        get { hotkey(forKey: Keys.zoomInHotkey) ?? Hotkey(keyCode: 24, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.zoomInHotkey) }
    }

    // ⌃⌥⌘-
    var zoomOutHotkey: Hotkey {
        get { hotkey(forKey: Keys.zoomOutHotkey) ?? Hotkey(keyCode: 27, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.zoomOutHotkey) }
    }

    // ⌃⌥⌘]
    var lensLargerHotkey: Hotkey {
        get { hotkey(forKey: Keys.lensLargerHotkey) ?? Hotkey(keyCode: 30, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.lensLargerHotkey) }
    }

    // ⌃⌥⌘[
    var lensSmallerHotkey: Hotkey {
        get { hotkey(forKey: Keys.lensSmallerHotkey) ?? Hotkey(keyCode: 33, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue) }
        set { setHotkey(newValue, forKey: Keys.lensSmallerHotkey) }
    }

    // MARK: - Drawing Color Picked With the Hotkey

    /// Whether a color picked with the hotkey becomes the Line Color setting
    var rememberDrawingColor: Bool {
        get { defaults.bool(forKey: Keys.rememberDrawingColor) }
        set { defaults.set(newValue, forKey: Keys.rememberDrawingColor) }
    }

    /// All 9 palette slots; the first `paletteColorCount` are offered
    static let maxPaletteColors = 9
    private static let defaultPaletteColors: [NSColor] = [
        .red, .systemYellow, .systemGreen, .systemBlue, .white, .systemOrange, .systemPurple, .systemPink, .black,
    ]

    var paletteColors: [NSColor] {
        get {
            guard let data = defaults.data(forKey: Keys.paletteColors),
                  let colors = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: NSColor.self, from: data),
                  colors.count == Self.maxPaletteColors else {
                return Self.defaultPaletteColors
            }
            return colors
        }
        set {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true) {
                defaults.set(data, forKey: Keys.paletteColors)
            }
        }
    }

    var paletteColorCount: Int {
        get {
            let count = defaults.integer(forKey: Keys.paletteColorCount)
            return (1...Self.maxPaletteColors).contains(count) ? count : 5
        }
        set { defaults.set(newValue, forKey: Keys.paletteColorCount) }
    }

    /// The colors offered by the palette
    var activePaletteColors: [NSColor] {
        Array(paletteColors.prefix(paletteColorCount))
    }

    /// A color picked with the hotkey that isn't saved; dropped when drawing mode is turned off
    var temporaryDrawingColor: NSColor?

    /// The color new strokes are drawn with
    var currentDrawingColor: NSColor {
        temporaryDrawingColor ?? drawingColor
    }

    // MARK: - Animation Durations (seconds)

    /// The outer ring shrinking on a mouse press; growing back on release takes 1.5 times as long
    var clickAnimationDuration: TimeInterval {
        get { duration(forKey: Keys.clickAnimationDuration, default: 0.2) }
        set { defaults.set(newValue, forKey: Keys.clickAnimationDuration) }
    }

    /// The ring fading in and out when mouse highlighting is turned on or off
    var ringFadeDuration: TimeInterval {
        get { duration(forKey: Keys.ringFadeDuration, default: 0.2) }
        set { defaults.set(newValue, forKey: Keys.ringFadeDuration) }
    }

    /// How long a keycap stays on screen
    var keycapDisplayTime: TimeInterval {
        get { duration(forKey: Keys.keycapDisplayTime, default: 3.0) }
        set { defaults.set(newValue, forKey: Keys.keycapDisplayTime) }
    }

    /// A keycap sliding in, and fading out
    var keycapAnimationDuration: TimeInterval {
        get { duration(forKey: Keys.keycapAnimationDuration, default: 0.3) }
        set { defaults.set(newValue, forKey: Keys.keycapAnimationDuration) }
    }

    /// How long drawings stay after ⇧ is released
    var drawingHoldTime: TimeInterval {
        get { duration(forKey: Keys.drawingHoldTime, default: 3.0) }
        set { defaults.set(newValue, forKey: Keys.drawingHoldTime) }
    }

    /// Drawings fading out
    var drawingFadeDuration: TimeInterval {
        get { duration(forKey: Keys.drawingFadeDuration, default: 0.5) }
        set { defaults.set(newValue, forKey: Keys.drawingFadeDuration) }
    }

    // 0 is a valid duration (no animation), so a missing value is told apart from 0
    private func duration(forKey key: String, default value: TimeInterval) -> TimeInterval {
        (defaults.object(forKey: key) as? NSNumber)?.doubleValue ?? value
    }

    private func hotkey(forKey key: String) -> Hotkey? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Hotkey.self, from: data)
    }

    private func setHotkey(_ hotkey: Hotkey, forKey key: String) {
        if let data = try? JSONEncoder().encode(hotkey) {
            defaults.set(data, forKey: key)
        }
    }

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
        defaults.removeObject(forKey: Keys.spotlightToggleHotkey)
        defaults.removeObject(forKey: Keys.zoomToggleHotkey)
        defaults.removeObject(forKey: Keys.allToggleHotkey)
        defaults.removeObject(forKey: Keys.undoDrawingHotkey)
        defaults.removeObject(forKey: Keys.nextDrawingColorHotkey)
        defaults.removeObject(forKey: Keys.zoomInHotkey)
        defaults.removeObject(forKey: Keys.zoomOutHotkey)
        defaults.removeObject(forKey: Keys.lensLargerHotkey)
        defaults.removeObject(forKey: Keys.lensSmallerHotkey)
        defaults.removeObject(forKey: Keys.rememberDrawingColor)
        defaults.removeObject(forKey: Keys.paletteColors)
        defaults.removeObject(forKey: Keys.paletteColorCount)
        temporaryDrawingColor = nil
        defaults.removeObject(forKey: Keys.clickAnimationDuration)
        defaults.removeObject(forKey: Keys.ringFadeDuration)
        defaults.removeObject(forKey: Keys.keycapDisplayTime)
        defaults.removeObject(forKey: Keys.keycapAnimationDuration)
        defaults.removeObject(forKey: Keys.drawingHoldTime)
        defaults.removeObject(forKey: Keys.drawingFadeDuration)
        defaults.removeObject(forKey: Keys.showModifierClicks)
        defaults.removeObject(forKey: Keys.shortcutPosition)
        defaults.removeObject(forKey: Keys.shortcutKeySize)
        defaults.removeObject(forKey: Keys.spotlightDiameter)
        defaults.removeObject(forKey: Keys.spotlightDimOpacity)
        defaults.removeObject(forKey: Keys.zoomDiameter)
        defaults.removeObject(forKey: Keys.zoomMagnification)
        defaults.removeObject(forKey: Keys.launchWithMouse)
        defaults.removeObject(forKey: Keys.launchWithKeyboard)
        defaults.removeObject(forKey: Keys.launchWithDrawing)
        defaults.removeObject(forKey: Keys.launchWithSpotlight)
        defaults.removeObject(forKey: Keys.checkForUpdatesAtLaunch)
    }
}
