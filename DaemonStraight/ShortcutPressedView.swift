//
//  ShortcutPressedView.swift
//  DaemonStraight
//
//  Display view for keyboard shortcuts
//

import Cocoa

class ShortcutPressedView: NSView {

    // MARK: - Properties
    private var shortcutKeys: [String]
    private var keyViews: [ButtonView] = []
    private let keySize: CGFloat
    private let keyPadding: CGFloat
    private var blurredBackground: BlurredView?

    // MARK: - Initialization
    init(frame: NSRect, shortcut: [String], keySize: CGFloat, keyPadding: CGFloat) {
        self.shortcutKeys = shortcut
        self.keySize = keySize
        self.keyPadding = keyPadding

        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.shortcutKeys = []
        self.keySize = 40
        self.keyPadding = 8
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup
    private func setupView() {
        wantsLayer = true

        // Create button views for each key
        var xOffset: CGFloat = keyPadding

        for key in shortcutKeys {
            let displayText = formatKeyName(key)
            let keyShape = KeyShape.forKey(displayText)
            let buttonWidth = keySize * keyShape.widthMultiplier

            let buttonFrame = NSRect(x: xOffset, y: keyPadding, width: buttonWidth, height: keySize)
            let button = ButtonView(frame: buttonFrame)
            button.character = displayText
            addSubview(button)
            keyViews.append(button)

            xOffset += buttonWidth + keyPadding
        }

        // Update frame size
        let totalWidth = xOffset
        let totalHeight = keySize + (keyPadding * 2)
        self.frame = NSRect(x: frame.origin.x, y: frame.origin.y, width: totalWidth, height: totalHeight)

        // Add blurred background AFTER calculating size
        let blur = BlurredView(frame: NSRect(origin: .zero, size: self.frame.size))
        blur.autoresizingMask = [.width, .height]
        addSubview(blur, positioned: .below, relativeTo: keyViews.first)
        blurredBackground = blur
    }

    private func formatKeyName(_ key: String) -> String {
        return KeyMapping.displayValue(for: key)
    }

    // MARK: - Hit Testing (Make view transparent to clicks)
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always return nil to allow clicks to pass through
        return nil
    }
}
