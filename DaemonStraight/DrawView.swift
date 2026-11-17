//
//  DrawView.swift
//  DaemonStraight
//
//  Canvas for freehand drawing triggered by shift key + mouse movement
//

import Cocoa

class DrawView: NSView {

    // What the stroke draws while the mouse moves: ⇧ freehand, ⌃⇧ a straight line, ⇧⌘ an arrow.
    // The kind can change in the middle of a stroke
    enum StrokeKind {
        case freehand, line, arrow
    }

    // MARK: - Properties
    private let settings = SettingsManager.shared
    private var completedPaths: [NSBezierPath] = []
    private var pathTimestamps: [Date] = []
    private var currentPath: NSBezierPath?
    private var currentKind: StrokeKind = .freehand
    // The straight part (line or arrow) being drawn: from where the stroke was when it started, to the mouse
    private var segmentStart: CGPoint = .zero
    private var segmentEnd: CGPoint = .zero

    private var fadeOutDuration: TimeInterval { settings.drawingHoldTime }
    private var fadeAnimationDuration: TimeInterval { settings.drawingFadeDuration }
    private var disappearanceTimer: Timer?
    private var countdownPaused: Bool = false
    private var lastDrawingCompletedTime: Date?

    private var isFading: Bool = false
    private var fadeStartTime: Date?
    private var fadeAnimationTimer: Timer?

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
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    // MARK: - Hit Testing (Make canvas transparent to clicks)
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always return nil to allow clicks to pass through to underlying apps
        return nil
    }

    // MARK: - Drawing State Management

    /// Start a stroke (shift key pressed)
    func startStroke(_ kind: StrokeKind, at point: CGPoint) {
        // Stop any active countdown and fade animation
        stopDisappearanceCountdown()
        if isFading {
            clearAllPathsImmediately()
        }

        let path = NSBezierPath()
        path.move(to: point)
        currentPath = path
        currentKind = kind
        segmentStart = point
        segmentEnd = point

        needsDisplay = true
    }

    /// Follow the mouse (shift held, mouse moving)
    func continueStroke(to point: CGPoint) {
        guard let path = currentPath else { return }

        if currentKind == .freehand {
            path.line(to: point)
        } else {
            segmentEnd = point
        }
        needsDisplay = true
    }

    /// Change what the stroke draws from here on (a modifier pressed or released while shift is held)
    func switchStroke(to kind: StrokeKind, at point: CGPoint) {
        guard let path = currentPath, kind != currentKind else { return }

        // The line or arrow drawn so far stays where it is
        if currentKind != .freehand {
            appendSegment(to: path)
        }
        currentKind = kind
        segmentStart = path.currentPoint
        segmentEnd = point
        if kind == .freehand {
            path.line(to: point)
        }

        needsDisplay = true
    }

    /// Finish the stroke (shift released). A stroke without any length (shift pressed for typing,
    /// not for drawing) is dropped
    func finishDrawing() {
        guard let path = currentPath else { return }

        if currentKind != .freehand {
            appendSegment(to: path)
        }
        currentPath = nil
        currentKind = .freehand

        if path.bounds.width >= 1 || path.bounds.height >= 1 {
            completedPaths.append(path)
            pathTimestamps.append(Date())
            lastDrawingCompletedTime = Date()
        }

        // Start disappearance countdown
        if !completedPaths.isEmpty {
            startDisappearanceCountdown()
        }

        needsDisplay = true
    }

    /// Cancel current drawing without finishing
    func cancelDrawing() {
        currentPath = nil
        currentKind = .freehand
        needsDisplay = true
    }

    /// Remove the last finished stroke
    func undoLastStroke() {
        guard currentPath == nil, !completedPaths.isEmpty else { return }

        completedPaths.removeLast()
        pathTimestamps.removeLast()
        if completedPaths.isEmpty {
            clearAllPathsImmediately()
        }
        needsDisplay = true
    }

    // Adds the straight part (and the arrowhead) to the stroke; the stroke goes on from its end
    private func appendSegment(to path: NSBezierPath) {
        path.line(to: segmentEnd)
        if currentKind == .arrow, let head = arrowHead(from: segmentStart, to: segmentEnd) {
            path.append(head)
            path.move(to: segmentEnd)
        }
    }

    // Two short lines back from the tip; nil while the arrow is too short to point anywhere
    private func arrowHead(from start: CGPoint, to end: CGPoint) -> NSBezierPath? {
        let dx = end.x - start.x
        let dy = end.y - start.y
        guard hypot(dx, dy) >= 2 else { return nil }

        let angle = atan2(dy, dx)
        let length = max(16, settings.drawingWidth * 3.5)
        let spread = CGFloat.pi / 6
        let head = NSBezierPath()
        for side in [angle + .pi - spread, angle + .pi + spread] {
            head.move(to: end)
            head.line(to: CGPoint(x: end.x + length * cos(side), y: end.y + length * sin(side)))
        }
        return head
    }

    // MARK: - Countdown Management

    func startDisappearanceCountdown() {
        stopDisappearanceCountdown()

        countdownPaused = false
        disappearanceTimer = Timer.scheduledTimer(withTimeInterval: fadeOutDuration, repeats: false) { [weak self] _ in
            self?.startFadeOutAnimation()
        }
    }

    func pauseDisappearanceCountdown() {
        guard !countdownPaused else { return }

        countdownPaused = true
        disappearanceTimer?.invalidate()
        disappearanceTimer = nil
    }

    func resumeDisappearanceCountdown() {
        guard countdownPaused else { return }

        // Restart countdown from beginning
        startDisappearanceCountdown()
    }

    func stopDisappearanceCountdown() {
        disappearanceTimer?.invalidate()
        disappearanceTimer = nil
        countdownPaused = false
    }

    // MARK: - Fade Animation

    private func startFadeOutAnimation() {
        guard !isFading else { return }

        isFading = true
        fadeStartTime = Date()

        // Start animation timer (60fps)
        fadeAnimationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            guard let startTime = self.fadeStartTime else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= self.fadeAnimationDuration {
                // Animation complete - clear everything
                timer.invalidate()
                self.clearAllPathsImmediately()
            } else {
                // Continue animation
                self.needsDisplay = true
            }
        }
    }

    private func getFadeAlpha() -> CGFloat {
        guard isFading, let startTime = fadeStartTime else {
            return 1.0
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / fadeAnimationDuration, 1.0)
        return CGFloat(1.0 - progress)
    }

    // MARK: - Clear Methods

    func clearAllPaths() {
        // Start fade animation instead of immediate clear
        startFadeOutAnimation()
    }

    private func clearAllPathsImmediately() {
        completedPaths.removeAll()
        pathTimestamps.removeAll()
        currentPath = nil
        currentKind = .freehand
        lastDrawingCompletedTime = nil
        isFading = false
        fadeStartTime = nil
        fadeAnimationTimer?.invalidate()
        fadeAnimationTimer = nil
        stopDisappearanceCountdown()
        needsDisplay = true
    }

    func clearAll() {
        clearAllPaths()
    }

    // MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.clear.setFill()
        dirtyRect.fill()

        // Get current fade alpha
        let fadeAlpha = getFadeAlpha()

        // Configure graphics context for neon glow effect
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw all completed paths with neon glow
        for path in completedPaths {
            stroke(path, alpha: fadeAlpha, in: context)
        }

        // Draw current path (in progress) - always full opacity
        if let path = currentPath {
            stroke(path, alpha: 1, in: context)

            if currentKind != .freehand {
                let segment = NSBezierPath()
                segment.move(to: segmentStart)
                segment.line(to: segmentEnd)
                if currentKind == .arrow, let head = arrowHead(from: segmentStart, to: segmentEnd) {
                    segment.append(head)
                }
                stroke(segment, alpha: 1, in: context)
            }
        }

        // Clear shadow for anything else
        context.setShadow(offset: .zero, blur: 0, color: nil)
    }

    private func stroke(_ path: NSBezierPath, alpha: CGFloat, in context: CGContext) {
        // Neon glow
        context.setShadow(
            offset: .zero,
            blur: 12.0,
            color: settings.drawingColor.withAlphaComponent(0.8 * alpha).cgColor
        )

        settings.drawingColor.withAlphaComponent(0.85 * alpha).setStroke()
        path.lineWidth = settings.drawingWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
}
