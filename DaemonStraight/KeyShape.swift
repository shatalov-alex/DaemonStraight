//
//  KeyShape.swift
//  DaemonStraight
//
//  Key shape definitions matching real keyboard layouts
//

import Foundation
import Cocoa

enum KeyShape {
    case square      // Regular keys (A-Z, 0-9, symbols)
    case wide        // Tab, Caps Lock, Backspace
    case extraWide   // Enter, Shift
    case spacebar    // Space - very wide
    case modifier    // Cmd, Option, Ctrl, Fn - medium wide

    // Get the width multiplier for this key shape (relative to standard key)
    var widthMultiplier: CGFloat {
        switch self {
        case .square:
            return 1.0
        case .wide:
            return 1.5
        case .extraWide:
            return 2.0
        case .spacebar:
            return 5.0
        case .modifier:
            return 1.3
        }
    }

    // Determine shape based on key name
    static func forKey(_ key: String) -> KeyShape {
        let lowercased = key.lowercased()

        // Spacebar
        if lowercased == "space" || key == "␣" {
            return .spacebar
        }

        // Modifiers
        if lowercased == "command" || lowercased == "cmd" || key == "⌘" ||
           lowercased == "option" || lowercased == "alt" || key == "⌥" ||
           lowercased == "control" || lowercased == "ctrl" || key == "⌃" ||
           lowercased == "fn" {
            return .modifier
        }

        // Extra wide keys
        if lowercased == "shift" || key == "⇧" ||
           lowercased == "enter" || lowercased == "return" || key == "↵" {
            return .extraWide
        }

        // Wide keys
        if lowercased == "tab" || key == "⇥" ||
           lowercased == "delete" || lowercased == "backspace" || key == "⌫" ||
           lowercased == "escape" || lowercased == "esc" || key == "⎋" ||
           lowercased == "capslock" || lowercased == "caps" || key == "⇪" {
            return .wide
        }

        // Default: square
        return .square
    }
}
