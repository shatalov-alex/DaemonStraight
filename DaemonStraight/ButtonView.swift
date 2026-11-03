//
//  ButtonView.swift
//  DaemonStraight
//
//  Custom view for displaying keyboard keys
//

import Cocoa

class ButtonView: NSView {

    // MARK: - Properties
    var character: String = "" {
        didSet {
            needsDisplay = true
        }
    }

    var cornerRadius: CGFloat = 12.0 {  // More rounded corners
        didSet {
            needsDisplay = true
        }
    }

    var shadowColor: NSColor = NSColor.black.withAlphaComponent(0.3) {
        didSet {
            needsDisplay = true
        }
    }

    var shadowBlurRadius: CGFloat = 4.0 {
        didSet {
            needsDisplay = true
        }
    }

    // MARK: - Initialization
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.masksToBounds = false
    }

    // MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw rounded rectangle with shadow
        let rect = bounds.insetBy(dx: 5, dy: 5)
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

        // Set shadow
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -2), blur: shadowBlurRadius, color: shadowColor.cgColor)

        // Fill background with slight gray tint for better visibility
        NSColor.white.withAlphaComponent(0.98).setFill()
        path.fill()

        context.restoreGState()

        // Draw darker border for better contrast
        NSColor.darkGray.withAlphaComponent(0.4).setStroke()
        path.lineWidth = 2.0
        path.stroke()

        // Draw character text - larger and bold for better readability
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: NSColor.black
        ]

        let text = character.uppercased()
        let textSize = text.size(withAttributes: attrs)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attrs)
    }

    // MARK: - Hit Testing (Make button transparent to clicks)
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always return nil to allow clicks to pass through
        return nil
    }
}
