//
//  CircleView.swift
//  DaemonStraight
//
//  Layer-based circle view for mouse highlighting
//  Uses CAShapeLayer for reliable rendering on transparent windows
//

import Cocoa
import QuartzCore

class CircleView: NSView {

    // MARK: - Properties
    private var innerRingLayer: CAShapeLayer!  // Static inner ring
    private var outerRingLayer: CAShapeLayer!  // Outer ring (animates on click)
    private let settings = SettingsManager.shared

    var ringColor: NSColor = NSColor.systemBlue {  // Neon blue by default
        didSet {
            updateLayers()
        }
    }

    var innerRadius: CGFloat = 43.0 {  // Inner ring radius
        didSet {
            updateLayers()
        }
    }

    var outerRadius: CGFloat = 50.0 {  // Outer ring radius
        didSet {
            updateLayers()
        }
    }

    var ringWidth: CGFloat = 7.0  // Width of each ring

    private var updateCount = 0  // Track updates for logging
    private var isShrinking = false  // Track if currently animating shrink
    private var shrinkTimer: Timer?  // Timer for continuous shrinking

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
        // CRITICAL: Use layer-backed view for transparent windows
        wantsLayer = true
        layer?.masksToBounds = false
        layer?.backgroundColor = NSColor.clear.cgColor

        NSLog("🎨 [CircleView] Initializing neon ring style")

        // Load settings FIRST (but don't trigger updates yet)
        loadSettings()

        // Create outer ring layer (larger, animates on click)
        outerRingLayer = CAShapeLayer()
        outerRingLayer.fillColor = NSColor.clear.cgColor  // Transparent center
        outerRingLayer.strokeColor = ringColor.withAlphaComponent(0.85).cgColor
        outerRingLayer.lineWidth = ringWidth
        outerRingLayer.shadowColor = ringColor.cgColor  // Neon glow
        outerRingLayer.shadowRadius = 10.0
        outerRingLayer.shadowOpacity = 0.9
        outerRingLayer.shadowOffset = .zero
        layer?.addSublayer(outerRingLayer)

        // Create inner ring layer (smaller, static)
        innerRingLayer = CAShapeLayer()
        innerRingLayer.fillColor = NSColor.clear.cgColor  // Transparent center
        innerRingLayer.strokeColor = ringColor.withAlphaComponent(0.5).cgColor
        innerRingLayer.lineWidth = ringWidth
        innerRingLayer.shadowColor = ringColor.cgColor  // Neon glow
        innerRingLayer.shadowRadius = 10.0
        innerRingLayer.shadowOpacity = 0.9
        innerRingLayer.shadowOffset = .zero
        layer?.addSublayer(innerRingLayer)

        // Now that layers are created, update them with correct paths
        updateLayersNow()

        // Listen for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: NSNotification.Name("SettingsChanged"),
            object: nil
        )

        NSLog("✅ [CircleView] Neon ring circle initialized")
    }

    private func loadSettings() {
        // Load size from settings and calculate radii
        let diameter = settings.mouseDiameter
        ringWidth = settings.mouseWidth
        ringColor = settings.mouseDefaultColor

        // Calculate radii based on diameter
        // The rings should touch perfectly: gap = ringWidth
        let radius = diameter / 2.0
        outerRadius = radius
        innerRadius = radius - ringWidth  // Rings touch perfectly
    }

    private func updateLayersNow() {
        // Direct update without guard check (only call when layers exist)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        // Create path for inner ring
        let innerPath = CGPath(
            ellipseIn: CGRect(x: center.x - innerRadius, y: center.y - innerRadius,
                            width: innerRadius * 2, height: innerRadius * 2),
            transform: nil
        )
        innerRingLayer.path = innerPath

        // Create path for outer ring
        let outerPath = CGPath(
            ellipseIn: CGRect(x: center.x - outerRadius, y: center.y - outerRadius,
                            width: outerRadius * 2, height: outerRadius * 2),
            transform: nil
        )
        outerRingLayer.path = outerPath

        // Update colors and width
        innerRingLayer.strokeColor = ringColor.withAlphaComponent(0.5).cgColor
        innerRingLayer.shadowColor = ringColor.cgColor
        innerRingLayer.lineWidth = ringWidth

        outerRingLayer.strokeColor = ringColor.withAlphaComponent(0.85).cgColor
        outerRingLayer.shadowColor = ringColor.cgColor
        outerRingLayer.lineWidth = ringWidth
    }

    @objc private func settingsChanged() {
        NSLog("🔄 [CircleView] Settings changed, reloading...")
        loadSettings()
        if innerRingLayer != nil && outerRingLayer != nil {
            // The finished click animation is kept on the layer (fillMode .forwards) and would
            // keep showing the old size/color of the outer ring - drop it when not pressed
            if !isShrinking {
                outerRingLayer.removeAllAnimations()
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            updateLayersNow()
            CATransaction.commit()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layer Management
    private func updateLayers() {
        // Safety check - only update if layers are initialized
        guard self.layer != nil, innerRingLayer != nil, outerRingLayer != nil else {
            return
        }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        // Create path for inner ring
        let innerPath = CGPath(
            ellipseIn: CGRect(x: center.x - innerRadius, y: center.y - innerRadius,
                            width: innerRadius * 2, height: innerRadius * 2),
            transform: nil
        )

        // Update layers without animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Only update outer ring if not animating
        if outerRingLayer.animation(forKey: "shrink") == nil &&
           outerRingLayer.animation(forKey: "expand") == nil {
            let outerPath = CGPath(
                ellipseIn: CGRect(x: center.x - outerRadius, y: center.y - outerRadius,
                                width: outerRadius * 2, height: outerRadius * 2),
                transform: nil
            )
            outerRingLayer.path = outerPath
        }
        outerRingLayer.frame = bounds

        innerRingLayer.path = innerPath
        innerRingLayer.frame = bounds

        CATransaction.commit()

        // Log only first few updates
        updateCount += 1
        if updateCount <= 3 {
            NSLog("🔄 [CircleView] Updated rings #\(updateCount) - center: (\(Int(center.x)), \(Int(center.y)))")
            NSLog("  💍 Inner ring: radius=\(Int(innerRadius)), opacity=\(innerRingLayer.opacity)")
            NSLog("  💍 Outer ring: radius=\(Int(outerRadius)), opacity=\(outerRingLayer.opacity)")
        }
    }

    override func layout() {
        super.layout()
        updateLayers()
    }

    override var frame: NSRect {
        didSet {
            if frame != oldValue {
                updateLayers()
            }
        }
    }

    // MARK: - Click Animation
    func startShrinking(color: NSColor) {
        guard !isShrinking else { return }
        isShrinking = true

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let shrunkPath = CGPath(
            ellipseIn: CGRect(x: center.x - innerRadius + 5, y: center.y - innerRadius + 5,
                            width: innerRadius * 2 - 10, height: innerRadius * 2 - 10),
            transform: nil
        )

        // Simple approach: just animate to the new state
        let animation = CAAnimationGroup()
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let pathAnim = CABasicAnimation(keyPath: "path")
        pathAnim.toValue = shrunkPath

        let colorAnim = CABasicAnimation(keyPath: "strokeColor")
        colorAnim.toValue = color.withAlphaComponent(0.9).cgColor

        let shadowAnim = CABasicAnimation(keyPath: "shadowColor")
        shadowAnim.toValue = color.cgColor

        animation.animations = [pathAnim, colorAnim, shadowAnim]
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        outerRingLayer.add(animation, forKey: "shrink")
    }

    func stopShrinking() {
        guard isShrinking else { return }
        isShrinking = false

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let expandedPath = CGPath(
            ellipseIn: CGRect(x: center.x - outerRadius, y: center.y - outerRadius,
                            width: outerRadius * 2, height: outerRadius * 2),
            transform: nil
        )

        // Simple approach: just animate back to original state
        let animation = CAAnimationGroup()
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let pathAnim = CABasicAnimation(keyPath: "path")
        pathAnim.toValue = expandedPath

        let colorAnim = CABasicAnimation(keyPath: "strokeColor")
        colorAnim.toValue = ringColor.withAlphaComponent(0.85).cgColor

        let shadowAnim = CABasicAnimation(keyPath: "shadowColor")
        shadowAnim.toValue = ringColor.cgColor

        animation.animations = [pathAnim, colorAnim, shadowAnim]
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        outerRingLayer.add(animation, forKey: "expand")
    }

    // Force visibility
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview != nil {
            NSLog("✅ [CircleView] Added to superview - ensuring visibility")
            layer?.isHidden = false
            updateLayers()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            NSLog("✅ [CircleView] Added to window - ensuring visibility")
            layer?.isHidden = false
            updateLayers()
        }
    }

    // MARK: - Hit Testing (Make circle transparent to clicks)
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always return nil to allow clicks to pass through
        return nil
    }
}
