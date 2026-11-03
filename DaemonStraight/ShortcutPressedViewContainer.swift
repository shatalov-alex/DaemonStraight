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
    private let margin: CGFloat = 20.0

    private let maxDisplayTime: TimeInterval = 3.0
    private let settings = SettingsManager.shared

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
            keySize: settings.shortcutKeySize,
            keyPadding: buttonsPadding
        )

        // Newest item sits nearest to the chosen screen edge and slides in from beyond it;
        // older items are pushed away from the edge
        let position = settings.shortcutPosition
        let startY = position.isTop ? bounds.height : -newView.frame.height
        newView.frame.origin = CGPoint(x: xPosition(for: newView, position: position), y: startY)
        let targetY = yPosition(for: newView, offset: 0, position: position)

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

    // Space taken by the menu bar, so top positions don't cover it
    private var topInset: CGFloat {
        guard let screen = window?.screen else { return 0 }
        return screen.frame.maxY - screen.visibleFrame.maxY
    }

    private func xPosition(for view: NSView, position: SettingsManager.ShortcutPosition) -> CGFloat {
        return position.isLeft ? margin : bounds.width - view.frame.width - margin
    }

    // offset: distance from the screen edge taken by newer items
    private func yPosition(for view: NSView, offset: CGFloat, position: SettingsManager.ShortcutPosition) -> CGFloat {
        if position.isTop {
            return bounds.height - topInset - margin - offset - view.frame.height
        }
        return margin + offset
    }

    private func repositionViews(animated: Bool) {
        let position = settings.shortcutPosition
        var offset: CGFloat = 0

        // Stack away from the edge, with NEWEST items nearest to it (reversed order)
        for view in shortcutViews.reversed() {
            let newOrigin = CGPoint(x: xPosition(for: view, position: position),
                                    y: yPosition(for: view, offset: offset, position: position))

            if animated {
                view.animator().frame.origin = newOrigin
            } else {
                view.frame.origin = newOrigin
            }

            offset += view.frame.height + shortcutViewsPadding
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
