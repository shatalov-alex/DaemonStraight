//
//  KeyMapping.swift
//  DaemonStraight
//
//  Comprehensive keyboard key mapping
//

import Foundation

struct KeyMapping {
    // Map of key codes/characters to display symbols
    static let keyMap: [String: String] = [
        // Modifiers
        "command": "⌘",
        "cmd": "⌘",
        "option": "⌥",
        "alt": "⌥",
        "control": "⌃",
        "ctrl": "⌃",
        "shift": "⇧",

        // Special keys
        "escape": "⎋",
        "esc": "⎋",
        "\u{1B}": "⎋",

        "tab": "⇥",
        "\t": "⇥",

        "return": "↵",
        "enter": "↵",
        "\r": "↵",
        "\n": "↵",

        "delete": "⌫",
        "backspace": "⌫",
        "\u{7F}": "⌫",

        "deleteforward": "⌦",
        "forwarddelete": "⌦",
        "\u{F728}": "⌦",

        "space": "␣",
        " ": "␣",

        // Arrow keys
        "up": "↑",
        "\u{F700}": "↑",

        "down": "↓",
        "\u{F701}": "↓",

        "left": "←",
        "\u{F702}": "←",

        "right": "→",
        "\u{F703}": "→",

        // Function keys
        "capslock": "⇪",
        "caps": "⇪",

        "home": "↖",
        "\u{F729}": "↖",

        "end": "↘",
        "\u{F72B}": "↘",

        "pageup": "⇞",
        "pgup": "⇞",
        "\u{F72C}": "⇞",

        "pagedown": "⇟",
        "pgdn": "⇟",
        "\u{F72D}": "⇟",

        "clear": "⌧",
        "help": "?⃝",

        // Function/fn key
        "fn": "fn",

        // Mouse clicks (shown with modifiers, e.g. ⌘ Click)
        "click": "Click",
        "right click": "Right Click",
        "\u{F747}": "fn",

        // F-keys (string names)
        "f1": "F1",
        "f2": "F2",
        "f3": "F3",
        "f4": "F4",
        "f5": "F5",
        "f6": "F6",
        "f7": "F7",
        "f8": "F8",
        "f9": "F9",
        "f10": "F10",
        "f11": "F11",
        "f12": "F12",
        "f13": "F13",
        "f14": "F14",
        "f15": "F15",
        "f16": "F16",
        "f17": "F17",
        "f18": "F18",
        "f19": "F19",
        "f20": "F20",

        // F-keys (unicode values on macOS)
        "\u{F704}": "F1",
        "\u{F705}": "F2",
        "\u{F706}": "F3",
        "\u{F707}": "F4",
        "\u{F708}": "F5",
        "\u{F709}": "F6",
        "\u{F70A}": "F7",
        "\u{F70B}": "F8",
        "\u{F70C}": "F9",
        "\u{F70D}": "F10",
        "\u{F70E}": "F11",
        "\u{F70F}": "F12",
        "\u{F710}": "F13",
        "\u{F711}": "F14",
        "\u{F712}": "F15",
        "\u{F713}": "F16",
        "\u{F714}": "F17",
        "\u{F715}": "F18",
        "\u{F716}": "F19",
        "\u{F717}": "F20",

        // Numbers (keep as is)
        "0": "0",
        "1": "1",
        "2": "2",
        "3": "3",
        "4": "4",
        "5": "5",
        "6": "6",
        "7": "7",
        "8": "8",
        "9": "9",

        // Letters (will be uppercased)
        "a": "A",
        "b": "B",
        "c": "C",
        "d": "D",
        "e": "E",
        "f": "F",
        "g": "G",
        "h": "H",
        "i": "I",
        "j": "J",
        "k": "K",
        "l": "L",
        "m": "M",
        "n": "N",
        "o": "O",
        "p": "P",
        "q": "Q",
        "r": "R",
        "s": "S",
        "t": "T",
        "u": "U",
        "v": "V",
        "w": "W",
        "x": "X",
        "y": "Y",
        "z": "Z",

        // Symbols
        "`": "`",
        "~": "~",
        "!": "!",
        "@": "@",
        "#": "#",
        "$": "$",
        "%": "%",
        "^": "^",
        "&": "&",
        "*": "*",
        "(": "(",
        ")": ")",
        "-": "-",
        "_": "_",
        "=": "=",
        "+": "+",
        "[": "[",
        "]": "]",
        "{": "{",
        "}": "}",
        "\\": "\\",
        "|": "|",
        ";": ";",
        ":": ":",
        "'": "'",
        "\"": "\"",
        ",": ",",
        ".": ".",
        "<": "<",
        ">": ">",
        "/": "/",
        "?": "?"
    ]

    static func displayValue(for key: String) -> String {
        // Try exact match first
        if let mapped = keyMap[key] {
            return mapped
        }

        // Try lowercase match
        if let mapped = keyMap[key.lowercased()] {
            return mapped
        }

        // If single character, uppercase it
        if key.count == 1 {
            return key.uppercased()
        }

        // Default: return as is, uppercased
        return key.uppercased()
    }
}
