//
//  BlurredView.swift
//  DaemonStraight
//
//  Blur effect background view
//

import Cocoa

class BlurredView: NSView {

    private var visualEffectView: NSVisualEffectView?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupBlur()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBlur()
    }

    private func setupBlur() {
        wantsLayer = true

        let blurView = NSVisualEffectView(frame: bounds)
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.autoresizingMask = [.width, .height]
        blurView.wantsLayer = true

        // Add rounded corners with glass effect
        blurView.layer?.cornerRadius = 12.0
        blurView.layer?.masksToBounds = true

        addSubview(blurView)
        visualEffectView = blurView

        // Apply rounded corners to parent view too
        layer?.cornerRadius = 12.0
        layer?.masksToBounds = true
    }

    // MARK: - Hit Testing (Make blur transparent to clicks)
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always return nil to allow clicks to pass through
        return nil
    }
}
