//
//  ZoomView.swift
//  DaemonStraight
//
//  Round magnifying lens around the cursor. The display is captured with ScreenCaptureKit
//  (without this app's own windows) and the lens shows an enlarged part of the picture
//

import Cocoa
import ScreenCaptureKit

class ZoomView: NSView {

    // MARK: - Properties
    private let settings = SettingsManager.shared

    // Circle that clips the picture (black where the picture ends, past the display's edges)
    private let lensLayer = CALayer()
    // The enlarged part of the display around the cursor (cut from the captured frame)
    private let pictureLayer = CALayer()
    // Where the display's picture is inside the captured frame, in unit coordinates from the bottom.
    // ScreenCaptureKit may shrink the picture and not fill the whole frame
    private var pictureArea = CGRect(x: 0, y: 0, width: 1, height: 1)
    // Ring around the lens (separate, so the clipping doesn't cut its shadow)
    private let borderLayer = CAShapeLayer()

    private var capture: DisplayCapture?
    private var lensCenter: CGPoint = .zero

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

        // No implicit animations: the lens follows the cursor at 60 fps
        let noActions: [String: CAAction] = ["position": NSNull(), "bounds": NSNull(), "contents": NSNull(),
                                             "contentsRect": NSNull(), "path": NSNull()]
        lensLayer.actions = noActions
        lensLayer.masksToBounds = true
        lensLayer.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(lensLayer)

        pictureLayer.actions = noActions
        pictureLayer.anchorPoint = .zero
        pictureLayer.contentsGravity = .resize
        lensLayer.addSublayer(pictureLayer)

        borderLayer.actions = noActions
        borderLayer.fillColor = nil
        borderLayer.strokeColor = NSColor.white.withAlphaComponent(0.9).cgColor
        borderLayer.lineWidth = 3
        borderLayer.shadowColor = NSColor.black.cgColor
        borderLayer.shadowOpacity = 0.5
        borderLayer.shadowRadius = 6
        borderLayer.shadowOffset = .zero
        layer?.addSublayer(borderLayer)

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
        capture?.stop()
    }

    // MARK: - Public Methods
    // Starts capturing the display this view is on
    func start() {
        guard capture == nil, let screen = window?.screen,
              let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return }

        let pixelSize = CGSize(width: screen.frame.width * screen.backingScaleFactor,
                               height: screen.frame.height * screen.backingScaleFactor)
        let capture = DisplayCapture { [weak self] surface, area in
            guard let self else { return }
            self.pictureLayer.contents = surface
            if area != self.pictureArea {
                self.pictureArea = area
                self.updatePicture()
            }
        }
        capture.start(displayID: displayID, pixelSize: pixelSize)
        self.capture = capture
    }

    func stop() {
        capture?.stop()
        capture = nil
        pictureLayer.contents = nil
        pictureArea = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    func move(to point: CGPoint) {
        lensCenter = point
        lensLayer.position = point
        borderLayer.position = point
        updatePicture()
    }

    // MARK: - Layer Management
    @objc private func settingsChanged() {
        rebuildLayers()
    }

    override func layout() {
        super.layout()
        rebuildLayers()
    }

    private func rebuildLayers() {
        let diameter = settings.zoomDiameter
        let bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        lensLayer.bounds = bounds
        lensLayer.cornerRadius = diameter / 2
        borderLayer.bounds = bounds
        borderLayer.path = CGPath(ellipseIn: bounds, transform: nil)
        move(to: lensCenter)
    }

    // The lens shows the square of side diameter / magnification around the cursor. Only its part
    // on the display is drawn (cut from the frame with contentsRect, placed where it belongs in the
    // lens), so near the edges the lens still centers on what's under the cursor, black beyond them
    private func updatePicture() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let magnification = settings.zoomMagnification
        let side = settings.zoomDiameter / magnification
        let source = CGRect(x: lensCenter.x - side / 2, y: lensCenter.y - side / 2, width: side, height: side)
        let visible = source.intersection(bounds)
        guard !visible.isEmpty else {
            pictureLayer.isHidden = true
            return
        }
        pictureLayer.isHidden = false

        let area = pictureArea
        pictureLayer.contentsRect = CGRect(x: area.minX + visible.minX / bounds.width * area.width,
                                           y: area.minY + visible.minY / bounds.height * area.height,
                                           width: visible.width / bounds.width * area.width,
                                           height: visible.height / bounds.height * area.height)
        pictureLayer.bounds = CGRect(x: 0, y: 0, width: visible.width * magnification,
                                     height: visible.height * magnification)
        pictureLayer.position = CGPoint(x: (visible.minX - source.minX) * magnification,
                                        y: (visible.minY - source.minY) * magnification)
    }

    // MARK: - Hit Testing (Make the lens transparent to clicks)
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

// Streams one display, without this app's windows, and hands each new frame to the main thread
private final class DisplayCapture: NSObject, SCStreamOutput, SCStreamDelegate {

    private let onFrame: (IOSurface, CGRect) -> Void
    private let queue = DispatchQueue(label: "me.shatalov.DaemonStraight.zoom")
    private var stream: SCStream?
    private var isRunning = false
    private var loggedFrameSize = false  // touched only on `queue`

    init(onFrame: @escaping (IOSurface, CGRect) -> Void) {
        self.onFrame = onFrame
    }

    func start(displayID: CGDirectDisplayID, pixelSize: CGSize) {
        isRunning = true
        // onScreenWindowsOnly: false - the on-screen list leaves out windows at the overlays' level,
        // and an app that isn't listed can't be excluded (the lens would then enlarge itself)
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { [weak self] content, error in
            DispatchQueue.main.async {
                guard let self, self.isRunning else { return }
                guard let content, let display = content.displays.first(where: { $0.displayID == displayID }) else {
                    NSLog("⚠️ [Zoom] Can't capture the display: \(error?.localizedDescription ?? "display not found")")
                    return
                }

                let ownApp = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
                guard !ownApp.isEmpty else {
                    NSLog("⚠️ [Zoom] Can't exclude own windows from the capture, not starting it")
                    return
                }
                let filter = SCContentFilter(display: display, excludingApplications: ownApp, exceptingWindows: [])

                let configuration = SCStreamConfiguration()
                configuration.width = Int(pixelSize.width)
                configuration.height = Int(pixelSize.height)
                configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
                configuration.pixelFormat = kCVPixelFormatType_32BGRA
                configuration.queueDepth = 5
                // The real cursor is drawn on top of the lens
                configuration.showsCursor = false

                let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
                do {
                    try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: self.queue)
                } catch {
                    NSLog("⚠️ [Zoom] Can't start the capture: \(error.localizedDescription)")
                    return
                }
                stream.startCapture { error in
                    if let error {
                        NSLog("⚠️ [Zoom] Capture failed to start: \(error.localizedDescription)")
                    }
                }
                self.stream = stream
                NSLog("🔍 [Zoom] Capturing display \(displayID)")
            }
        }
    }

    func stop() {
        isRunning = false
        stream?.stopCapture { _ in }
        stream = nil
    }

    // MARK: - SCStreamOutput
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Frames without a picture (nothing changed on screen) keep the previous one in the lens
        guard type == .screen, let pixelBuffer = sampleBuffer.imageBuffer,
              let surface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return }
        let area = Self.pictureArea(of: sampleBuffer, surface: surface)
        if !loggedFrameSize {
            loggedFrameSize = true
            NSLog("🔍 [Zoom] Frame \(IOSurfaceGetWidth(surface))×\(IOSurfaceGetHeight(surface)), picture in \(area)")
        }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.onFrame(surface, area)
        }
    }

    // The frame's contentRect (points, from the top) as unit coordinates from the bottom
    private static func pictureArea(of sampleBuffer: CMSampleBuffer, surface: IOSurface) -> CGRect {
        let full = CGRect(x: 0, y: 0, width: 1, height: 1)
        guard let info = (CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
                            as? [[SCStreamFrameInfo: Any]])?.first,
              let rectInfo = info[.contentRect], CFGetTypeID(rectInfo as CFTypeRef) == CFDictionaryGetTypeID(),
              let rect = CGRect(dictionaryRepresentation: rectInfo as! CFDictionary),
              let scale = (info[.scaleFactor] as? NSNumber)?.doubleValue else { return full }
        let width = CGFloat(IOSurfaceGetWidth(surface)), height = CGFloat(IOSurfaceGetHeight(surface))
        guard width > 0, height > 0, rect.width > 0, rect.height > 0 else { return full }
        return CGRect(x: rect.minX * scale / width, y: 1 - rect.maxY * scale / height,
                      width: rect.width * scale / width, height: rect.height * scale / height)
    }

    // MARK: - SCStreamDelegate
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        NSLog("⚠️ [Zoom] Capture stopped: \(error.localizedDescription)")
    }
}

