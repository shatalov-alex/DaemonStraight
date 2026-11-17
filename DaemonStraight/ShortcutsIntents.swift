//
//  ShortcutsIntents.swift
//  DaemonStraight
//
//  Actions for the Shortcuts app: turn features on or off, clear the drawing
//

import AppIntents
import Cocoa

enum ShortcutsFeature: String, AppEnum {
    case mouse, keyboard, drawing, spotlight, zoom, all

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Feature"
    static var caseDisplayRepresentations: [ShortcutsFeature: DisplayRepresentation] = [
        .mouse: "Mouse Highlighting",
        .keyboard: "Keyboard Display",
        .drawing: "Drawing Mode",
        .spotlight: "Spotlight",
        .zoom: "Zoom",
        .all: "All Features",
    ]
}

enum ShortcutsFeatureState: String, AppEnum {
    case on, off, toggle

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "State"
    static var caseDisplayRepresentations: [ShortcutsFeatureState: DisplayRepresentation] = [
        .on: "On",
        .off: "Off",
        .toggle: "Toggle",
    ]
}

struct SetFeatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Turn DaemonStraight Feature On or Off"
    static var description = IntentDescription(
        "Turns a DaemonStraight feature on or off, like its hotkey. \"All Features\" works like Turn All On / Turn All Off: Zoom is only turned off.")
    // The app works from the menu bar; it must not take the focus from the app being presented
    static var openAppWhenRun = false

    @Parameter(title: "Feature", default: .mouse)
    var feature: ShortcutsFeature

    @Parameter(title: "State", default: .on)
    var state: ShortcutsFeatureState

    static var parameterSummary: some ParameterSummary {
        Summary("Turn \(\.$feature) \(\.$state)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let on: Bool? = switch state {
        case .on: true
        case .off: false
        case .toggle: nil
        }
        (NSApp.delegate as? AppDelegate)?.setFeature(feature, on: on)
        return .result()
    }
}

struct ClearDrawingIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear DaemonStraight Drawing"
    static var description = IntentDescription("Removes everything drawn on the screen.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        (NSApp.delegate as? AppDelegate)?.clearDrawingFromShortcut()
        return .result()
    }
}
