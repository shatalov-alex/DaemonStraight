//
//  SpotlightView.swift
//  DaemonStraight
//
//  Dims the screen except a soft-edged circle around the cursor
//

import Cocoa
import QuartzCore

class SpotlightView: NSView {

    // MARK: - Properties
    private let settings = SettingsManager.shared

    // Dimmed area with a hole in the middle. It's twice the size of the view, so moving it
    // (instead of rebuilding the path) is enough to follow the cursor to any corner
    private let dimLayer = CAShapeLayer()

    // Soft edge: radial gradient inside the hole, from clear in the centre to the dim color
    private let edgeLayer = CAGradientLayer()
    private let edgeMask = CAShapeLayer()

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

        dimLayer.fillRule = .evenOdd
        layer?.addSublayer(dimLayer)

        edgeLayer.type = .radial
        edgeLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        edgeLayer.endPoint = CGPoint(x: 1, y: 1)
        edgeLayer.locations = [0, 0.6, 1]
        edgeLayer.mask = edgeMask
        layer?.addSublayer(edgeLayer)

        rebuildLayers()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: NSNotification.Name("SettingsChanged"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods
    func move(to point: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dimLayer.position = point
        edgeLayer.position = point
        CATransaction.commit()
    }

    // MARK: - Layer Management
    @objc private func settingsChanged() {
        let position = dimLayer.position
        rebuildLayers()
        move(to: position)
    }

    override func layout() {
        super.layout()
        rebuildLayers()
    }

    private func rebuildLayers() {
        let radius = settings.spotlightDiameter / 2
        let dimColor = NSColor.black.withAlphaComponent(settings.spotlightDimOpacity).cgColor
        let clearColor = NSColor.black.withAlphaComponent(0).cgColor

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let size = CGSize(width: bounds.width * 2, height: bounds.height * 2)
        dimLayer.bounds = CGRect(origin: .zero, size: size)
        let path = CGMutablePath()
        path.addRect(dimLayer.bounds)
        path.addEllipse(in: CGRect(x: size.width / 2 - radius, y: size.height / 2 - radius, width: radius * 2, height: radius * 2))
        dimLayer.path = path
        dimLayer.fillColor = dimColor

        edgeLayer.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        edgeLayer.colors = [clearColor, clearColor, dimColor]
        edgeMask.frame = edgeLayer.bounds
        edgeMask.path = CGPath(ellipseIn: edgeLayer.bounds, transform: nil)

        CATransaction.commit()
    }

    // MARK: - Hit Testing (Make spotlight transparent to clicks)
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}
