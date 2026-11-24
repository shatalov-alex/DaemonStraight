//
//  URLCommand.swift
//  DaemonStraight
//
//  What a daemonstraight:// link asks for:
//  daemonstraight://<mouse|keyboard|drawing|spotlight|zoom|all>/<on|off|toggle>, daemonstraight://clear
//

import Foundation

enum URLCommand: Equatable {
    /// Turn a feature on (true), off (false) or over (nil)
    case feature(ShortcutsFeature, on: Bool?)
    case clearDrawing

    /// nil for anything else: any app or web page can open a link, so nothing is guessed
    init?(_ url: URL) {
        guard let host = url.host?.lowercased() else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }.map { $0.lowercased() }

        if host == "clear" && path.isEmpty {
            self = .clearDrawing
            return
        }
        guard let feature = ShortcutsFeature(rawValue: host), path.count == 1,
              let state = ShortcutsFeatureState(rawValue: path[0]) else { return nil }
        self = .feature(feature, on: state.isOn)
    }
}
