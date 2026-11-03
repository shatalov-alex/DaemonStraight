//
//  DrawView.swift
//  DaemonStraight
//
//  Canvas for freehand drawing triggered by shift key + mouse movement
//

import Cocoa

class DrawView: NSView {

    // MARK: - Properties
    private let settings = SettingsManager.shared
    private var completedPaths: [NSBezierPath] = []
    private var pathTimestamps: [Date] = []
    private var currentPath: NSBezierPath?
    private var currentPathStartPoint: CGPoint = .zero
    private var isDrawingStraightLine: Bool = false
    private var currentLineEndPoint: CGPoint = .zero

    private let fadeOutDuration: TimeInterval = 3.0
    private let fadeAnimationDuration: TimeInterval = 0.5
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

    /// Start freehand drawing (shift key pressed)
    func startFreehandDrawing(at point: CGPoint) {
        // Stop any active countdown and fade animation
        stopDisappearanceCountdown()
        if isFading {
            clearAllPathsImmediately()
        }

        let path = NSBezierPath()
        path.move(to: point)
        path.lineWidth = settings.drawingWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        currentPath = path
        currentPathStartPoint = point
        isDrawingStraightLine = false

        needsDisplay = true
    }

    /// Continue freehand drawing (shift held, mouse moving)
    func continueFreehandDrawing(to point: CGPoint) {
        guard let path = currentPath, !isDrawingStraightLine else { return }

        path.line(to: point)
        needsDisplay = true
    }

    /// Start straight line drawing (ctrl+shift pressed)
    func startStraightLineDrawing(at point: CGPoint) {
        // Stop any active countdown and fade animation
        stopDisappearanceCountdown()
        if isFading {
            clearAllPathsImmediately()
        }

        let path = NSBezierPath()
        path.move(to: point)
        path.lineWidth = settings.drawingWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        currentPath = path
        currentPathStartPoint = point
        currentLineEndPoint = point
        isDrawingStraightLine = true

        needsDisplay = true
    }

    /// Update straight line endpoint (ctrl+shift held, mouse moving)
    func updateStraightLineEndpoint(to point: CGPoint) {
        guard isDrawingStraightLine else { return }

        currentLineEndPoint = point
        needsDisplay = true
    }

    /// Switch existing drawing to straight line mode
    func switchToStraightLineMode(at point: CGPoint) {
        guard let path = currentPath, !isDrawingStraightLine else { return }

        // Save the start point from the current freehand path
        currentPathStartPoint = path.isEmpty ? point : currentPathStartPoint
        currentLineEndPoint = point
        isDrawingStraightLine = true

        needsDisplay = true
    }

    /// Switch existing drawing to freehand mode
    func switchToFreehandMode(at point: CGPoint) {
        guard let path = currentPath, isDrawingStraightLine else { return }

        // Finalize the straight line into the path
        path.line(to: currentLineEndPoint)

        // Continue from the endpoint as freehand
        isDrawingStraightLine = false

        needsDisplay = true
    }

    /// Finish current drawing (shift or ctrl+shift released)
    func finishDrawing() {
        guard let path = currentPath else { return }

        // If it was a straight line, finalize it
        if isDrawingStraightLine {
            path.line(to: currentLineEndPoint)
        }

        // Move to completed paths
        completedPaths.append(path)
        pathTimestamps.append(Date())

        currentPath = nil
        isDrawingStraightLine = false
        lastDrawingCompletedTime = Date()

        // Start disappearance countdown
        startDisappearanceCountdown()

        needsDisplay = true
    }

    /// Cancel current drawing without finishing
    func cancelDrawing() {
        currentPath = nil
        isDrawingStraightLine = false
        needsDisplay = true
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
        isDrawingStraightLine = false
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
            // Set up shadow for neon effect
            context.setShadow(
                offset: .zero,
                blur: 12.0,
                color: settings.drawingColor.withAlphaComponent(0.8 * fadeAlpha).cgColor
            )

            settings.drawingColor.withAlphaComponent(0.85 * fadeAlpha).setStroke()
            path.lineWidth = settings.drawingWidth  // Bolder line
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }

        // Draw current path (in progress) - always full opacity
        if let path = currentPath {
            if isDrawingStraightLine {
                // Draw straight line from start to current endpoint with neon glow
                let straightPath = NSBezierPath()
                straightPath.move(to: currentPathStartPoint)
                straightPath.line(to: currentLineEndPoint)
                straightPath.lineWidth = settings.drawingWidth
                straightPath.lineCapStyle = .round

                // Neon glow for straight line
                context.setShadow(
                    offset: .zero,
                    blur: 12.0,
                    color: settings.drawingColor.withAlphaComponent(0.8).cgColor
                )

                settings.drawingColor.withAlphaComponent(0.85).setStroke()
                straightPath.stroke()
            } else {
                // Draw freehand path with neon glow
                context.setShadow(
                    offset: .zero,
                    blur: 12.0,
                    color: settings.drawingColor.withAlphaComponent(0.8).cgColor
                )

                settings.drawingColor.withAlphaComponent(0.85).setStroke()
                path.lineWidth = settings.drawingWidth
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }
        }

        // Clear shadow for anything else
        context.setShadow(offset: .zero, blur: 0, color: nil)
    }
}
