//
//  ColorPalettePanel.swift
//  DaemonStraight
//
//  Numbered drawing colors shown with the Next Drawing Color hotkey: a number key (or a click) picks one,
//  Esc or the hotkey again closes it
//

import Cocoa

final class ColorPalettePanel: NSPanel {

    /// Called with the index of the picked color; the panel closes itself
    var onPick: ((Int) -> Void)?
    var onClose: (() -> Void)?

    private let colorCount: Int
    private var isClosing = false

    // keyCodes of 1...9 on the top row and on the keypad
    private static let digitKeyCodes: [UInt16: Int] = [
        18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8,
        83: 0, 84: 1, 85: 2, 86: 3, 87: 4, 88: 5, 89: 6, 91: 7, 92: 8,
    ]

    init(colors: [NSColor], selected: Int?, near point: CGPoint) {
        colorCount = colors.count
        let content = PaletteView(colors: colors, selected: selected)
        // Shown above the cursor, kept on its display
        var frame = NSRect(origin: .zero, size: content.frame.size)
        frame.origin = CGPoint(x: point.x - frame.width / 2, y: point.y + 40)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) {
            let visible = screen.visibleFrame
            frame.origin.x = min(max(frame.origin.x, visible.minX + 8), visible.maxX - frame.width - 8)
            if frame.maxY > visible.maxY - 8 {
                frame.origin.y = point.y - 40 - frame.height
            }
        }

        // Non-activating: takes the key presses without making DaemonStraight the active app,
        // so the app being presented stays in front and the number isn't typed into it
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        // Same level as the overlays; kept in front of them by the window maintenance
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        contentView = content
        content.onClick = { [weak self] index in self?.pick(index) }
    }

    override var canBecomeKey: Bool { true }

    func show() {
        makeKeyAndOrderFront(nil)
        orderFrontRegardless()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {  // Esc
            close()
        } else if let index = Self.digitKeyCodes[event.keyCode], index < colorCount {
            pick(index)
        }
        // Anything else is ignored (no beep)
    }

    // Clicking somewhere else closes it
    override func resignKey() {
        super.resignKey()
        close()
    }

    override func close() {
        guard !isClosing else { return }
        isClosing = true
        super.close()
        onClose?()
    }

    private func pick(_ index: Int) {
        onPick?(index)
        close()
    }
}

// The swatches with their numbers; the current color is outlined
private final class PaletteView: NSView {
    var onClick: ((Int) -> Void)?

    private let colors: [NSColor]
    private let selected: Int?
    private let swatch: CGFloat = 36
    private let spacing: CGFloat = 12
    private let padding: CGFloat = 14
    private let numberHeight: CGFloat = 18

    init(colors: [NSColor], selected: Int?) {
        self.colors = colors
        self.selected = selected
        let width = padding * 2 + CGFloat(colors.count) * swatch + CGFloat(max(colors.count - 1, 0)) * spacing
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: padding * 2 + swatch + 4 + numberHeight))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func swatchRect(_ index: Int) -> NSRect {
        NSRect(x: padding + CGFloat(index) * (swatch + spacing), y: padding + numberHeight + 4, width: swatch, height: swatch)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14).fill()

        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
        for (index, color) in colors.enumerated() {
            let rect = swatchRect(index)
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            NSColor.white.withAlphaComponent(0.35).setStroke()
            NSBezierPath(ovalIn: rect).stroke()
            if index == selected {
                let ring = NSBezierPath(ovalIn: rect.insetBy(dx: -4, dy: -4))
                ring.lineWidth = 2.5
                NSColor.white.setStroke()
                ring.stroke()
            }

            let number = NSAttributedString(string: "\(index + 1)", attributes: numberAttributes)
            let size = number.size()
            number.draw(at: CGPoint(x: rect.midX - size.width / 2, y: padding))
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let index = colors.indices.first(where: { swatchRect($0).insetBy(dx: -4, dy: -4).contains(point) }) {
            onClick?(index)
        }
    }
}
