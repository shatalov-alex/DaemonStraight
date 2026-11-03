//
//  TransparentOverlayWindow.swift
//  DaemonStraight
//
//  Custom window that stays transparent and never becomes key/main
//

import Cocoa

class TransparentOverlayWindow: NSWindow {

    // Prevent window from becoming key (never gains focus)
    override var canBecomeKey: Bool {
        return false
    }

    // Prevent window from becoming main
    override var canBecomeMain: Bool {
        return false
    }
}
