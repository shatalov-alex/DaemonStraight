//
//  ShortcutPressedViewContainer.swift
//  DaemonStraight
//
//  Container managing multiple shortcut views
//

import Cocoa

class ShortcutPressedViewContainer: NSView {

    // MARK: - Properties
    private var shortcutViews: [ShortcutPressedView] = []
    private var buttonsPadding: CGFloat = 8.0
    private var shortcutViewsPadding: CGFloat = 10.0

    private let keySize: CGFloat = 70.0  // Slightly bigger for better visibility
    private let maxDisplayTime: TimeInterval = 3.0

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
        layer?.masksToBounds = false  // Don't clip subviews
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    // MARK: - Hit Testing (Make container transparent to clicks)
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always return nil to allow clicks to pass through
        return nil
    }

    // MARK: - Public Methods
    func addViewSubview(_ shortcut: [String]) {
        // Create new shortcut view
        let newView = ShortcutPressedView(
            frame: .zero,
            shortcut: shortcut,
            keySize: keySize,
            keyPadding: buttonsPadding
        )

        // Position on LEFT side, starting from BELOW screen (animate up from bottom)
        let leftMargin: CGFloat = 20.0
        let bottomMargin: CGFloat = 20.0
        let startY: CGFloat = -newView.frame.height  // Start below screen
        newView.frame.origin = CGPoint(x: leftMargin, y: startY)

        // Calculate target position - new items at bottom, old items pushed up
        // Target Y is always at the bottom margin for newest item
        let targetY = bottomMargin

        newView.alphaValue = 0

        addSubview(newView)
        shortcutViews.append(newView)

        // Animate in
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)

            newView.animator().alphaValue = 1.0
            newView.animator().frame.origin.y = targetY

            // Reposition existing views
            repositionViews(animated: true)
        }, completionHandler: {
            // Schedule removal
            self.scheduleRemoval(of: newView)
        })
    }

    // MARK: - Private Methods
    private func calculateTotalHeight() -> CGFloat {
        var total: CGFloat = 0
        for view in shortcutViews {
            total += view.frame.height + shortcutViewsPadding
        }
        return total
    }

    private func repositionViews(animated: Bool) {
        let leftMargin: CGFloat = 20.0
        let bottomMargin: CGFloat = 20.0
        var yOffset = bottomMargin

        // Stack from bottom to top, with NEWEST items at bottom (reversed order)
        for view in shortcutViews.reversed() {
            let newOrigin = CGPoint(x: leftMargin, y: yOffset)

            if animated {
                view.animator().frame.origin = newOrigin
            } else {
                view.frame.origin = newOrigin
            }

            yOffset += view.frame.height + shortcutViewsPadding
        }
    }

    private func scheduleRemoval(of view: ShortcutPressedView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + maxDisplayTime) { [weak self] in
            self?.removeShortcutView(view)
        }
    }

    private func removeShortcutView(_ view: ShortcutPressedView) {
        guard shortcutViews.contains(view) else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)

            view.animator().alphaValue = 0.0
        }, completionHandler: {
            view.removeFromSuperview()
            self.shortcutViews.removeAll { $0 == view }
            self.repositionViews(animated: true)
        })
    }

    func clearAll() {
        for view in shortcutViews {
            view.removeFromSuperview()
        }
        shortcutViews.removeAll()
    }
}
