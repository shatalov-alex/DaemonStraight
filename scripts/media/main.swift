// Capture harness for README media: drives the app's real views on a neutral canvas in its own windows
// and captures only those windows (no Screen Recording needed, nothing else on screen is captured)

import Cocoa
import ImageIO
import UniformTypeIdentifiers

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
let canvasSize = CGSize(width: 880, height: 520)

// MARK: - Window capture

func capture(_ windows: [NSWindow], bounds: CGRect = .null, best: Bool) -> CGImage? {
    var ids: [UnsafeRawPointer?] = windows.map { UnsafeRawPointer(bitPattern: UInt($0.windowNumber)) }
    let array = CFArrayCreate(nil, &ids, ids.count, nil)!
    var options: CGWindowImageOption = [.boundsIgnoreFraming]
    options.insert(best ? .bestResolution : .nominalResolution)
    return CGImage(windowListFromArrayScreenBounds: bounds, windowArray: array, imageOption: options)
}

func writePNG(_ image: CGImage, _ name: String) {
    let url = outDir.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(name) \(image.width)x\(image.height)")
}

// MARK: - GIF recorder

@MainActor final class Recorder {
    private var frames: [CGImage] = []
    private var timer: Timer?
    private let fps = 20.0
    var windows: [NSWindow]
    let bounds: CGRect

    init(windows: [NSWindow], bounds: CGRect) {
        self.windows = windows
        self.bounds = bounds
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1 / fps, repeats: true) { _ in
            MainActor.assumeIsolated {
                if let image = capture(self.windows, bounds: self.bounds, best: false) { self.frames.append(image) }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop(_ name: String) {
        timer?.invalidate()
        let url = outDir.appendingPathComponent(name)
        let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames.count, nil)!
        CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        let frameProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps,
                                                          kCGImagePropertyGIFUnclampedDelayTime: 1 / fps]] as CFDictionary
        for frame in frames { CGImageDestinationAddImage(dest, frame, frameProps) }
        CGImageDestinationFinalize(dest)
        print("wrote \(name) (\(frames.count) frames)")
    }
}

func pause(_ seconds: Double) async {
    try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
}

// MARK: - Neutral canvas (a plain slide)

final class CanvasView: NSView {
    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.97, alpha: 1).setFill()
        bounds.fill()

        let card = bounds.insetBy(dx: 40, dy: 36)
        NSColor.white.setFill()
        NSBezierPath(roundedRect: card, xRadius: 14, yRadius: 14).fill()
        NSColor(white: 0.85, alpha: 1).setStroke()
        NSBezierPath(roundedRect: card, xRadius: 14, yRadius: 14).stroke()

        let title: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 30, weight: .bold),
                                                    .foregroundColor: NSColor(white: 0.15, alpha: 1)]
        NSAttributedString(string: "Release Overview", attributes: title).draw(at: CGPoint(x: 80, y: 400))
        let sub: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 15),
                                                  .foregroundColor: NSColor(white: 0.45, alpha: 1)]
        NSAttributedString(string: "Builds per week, last five weeks", attributes: sub).draw(at: CGPoint(x: 82, y: 372))

        // Bar chart
        let values: [CGFloat] = [0.45, 0.6, 0.52, 0.8, 0.95]
        let base = CGPoint(x: 90, y: 90)
        NSColor(white: 0.8, alpha: 1).setFill()
        NSRect(x: base.x - 10, y: base.y - 2, width: 360, height: 2).fill()
        for (i, v) in values.enumerated() {
            let rect = NSRect(x: base.x + CGFloat(i) * 70, y: base.y, width: 44, height: 240 * v)
            (i == values.count - 1 ? NSColor(calibratedRed: 0.20, green: 0.45, blue: 0.85, alpha: 1)
                                   : NSColor(calibratedRed: 0.62, green: 0.72, blue: 0.86, alpha: 1)).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5).fill()
            let label = NSAttributedString(string: "W\(i + 1)", attributes: [.font: NSFont.systemFont(ofSize: 12),
                                                                            .foregroundColor: NSColor.gray])
            label.draw(at: CGPoint(x: rect.midX - label.size().width / 2, y: base.y - 22))
        }

        // Notes with small print (for the zoom lens)
        let head: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 17, weight: .semibold),
                                                   .foregroundColor: NSColor(white: 0.2, alpha: 1)]
        NSAttributedString(string: "Notes", attributes: head).draw(at: CGPoint(x: 500, y: 320))
        let small: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9),
                                                    .foregroundColor: NSColor(white: 0.35, alpha: 1)]
        let lines = ["Build times went down after the cache change.",
                     "Week 5 includes two hotfix builds.",
                     "Small print like this is hard to read",
                     "in a shared screen, but easy in the lens.",
                     "Next review: after the 1.4 release."]
        for (i, line) in lines.enumerated() {
            NSAttributedString(string: "• " + line, attributes: small).draw(at: CGPoint(x: 502, y: 296 - CGFloat(i) * 16))
        }
        // Placeholder text blocks
        NSColor(white: 0.9, alpha: 1).setFill()
        for i in 0..<3 {
            NSBezierPath(roundedRect: NSRect(x: 502, y: 170 - CGFloat(i) * 24, width: 280 - CGFloat(i) * 50, height: 10),
                         xRadius: 5, yRadius: 5).fill()
        }
    }
}

// MARK: - Scenes

@MainActor final class Harness {
    let settings = SettingsManager.shared
    var canvasWindow: NSWindow!
    var canvas: CanvasView!
    let cursor = NSImageView()

    func makeCanvas() {
        let screen = NSScreen.main!.visibleFrame
        let frame = NSRect(x: screen.midX - canvasSize.width / 2, y: screen.midY - canvasSize.height / 2,
                           width: canvasSize.width, height: canvasSize.height)
        canvasWindow = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        canvasWindow.level = .floating
        canvas = CanvasView(frame: NSRect(origin: .zero, size: canvasSize))
        canvas.wantsLayer = true
        canvasWindow.contentView = canvas
        canvasWindow.appearance = NSAppearance(named: .aqua)
        canvasWindow.orderFrontRegardless()

        let image = NSCursor.arrow.image
        cursor.image = image
        cursor.frame = NSRect(origin: .zero, size: image.size)
        cursor.isHidden = true
    }

    var canvasBounds: CGRect {
        // Screen bounds for the capture API: top-left origin
        let f = canvasWindow.frame
        let mainHeight = NSScreen.screens[0].frame.height
        return CGRect(x: f.minX, y: mainHeight - f.maxY, width: f.width, height: f.height)
    }

    func clearOverlays() {
        canvas.subviews.forEach { $0.removeFromSuperview() }
    }

    func showCursor(at p: CGPoint) {
        if cursor.superview == nil { canvas.addSubview(cursor) }
        cursor.isHidden = false
        let hot = NSCursor.arrow.hotSpot
        cursor.frame.origin = CGPoint(x: p.x - hot.x, y: p.y - cursor.frame.height + hot.y)
    }

    func bringCursorToFront() {
        cursor.removeFromSuperview()
        canvas.addSubview(cursor)
    }

    // Moves along a smooth path, calling step at 60 fps
    func glide(from a: CGPoint, to b: CGPoint, duration: Double, step: (CGPoint) -> Void) async {
        let n = max(Int(duration * 60), 1)
        for i in 1...n {
            let t = Double(i) / Double(n)
            let e = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
            step(CGPoint(x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e))
            await pause(1 / 60)
        }
    }

    // MARK: Mouse
    func mouseScene() async {
        clearOverlays()
        let ring = CircleView(frame: NSRect(x: 0, y: 0, width: 150, height: 150))
        canvas.addSubview(ring)
        func place(_ p: CGPoint) {
            CATransaction.begin(); CATransaction.setDisableActions(true)
            ring.frame.origin = CGPoint(x: p.x - 75, y: p.y - 75)
            CATransaction.commit()
            showCursor(at: p)
        }
        bringCursorToFront()
        var p = CGPoint(x: 200, y: 260)
        place(p)
        let rec = Recorder(windows: [canvasWindow], bounds: canvasBounds)
        rec.start()
        await pause(0.4)
        await glide(from: p, to: CGPoint(x: 390, y: 330), duration: 1.0) { place($0) }; p = CGPoint(x: 390, y: 330)
        await pause(0.3)
        ring.startShrinking(color: settings.mouseLeftClickColor)
        await pause(0.7)
        ring.stopShrinking()
        await pause(0.6)
        await glide(from: p, to: CGPoint(x: 620, y: 250), duration: 1.0) { place($0) }; p = CGPoint(x: 620, y: 250)
        await pause(0.3)
        ring.startShrinking(color: settings.mouseRightClickColor)
        await pause(0.7)
        ring.stopShrinking()
        await pause(0.8)
        rec.stop("feature-mouse.gif")
    }

    // MARK: Keycaps
    func keyboardScene() async {
        clearOverlays()
        cursor.isHidden = true
        let keys = ShortcutPressedViewContainer(frame: canvas.bounds)
        canvas.addSubview(keys)
        let rec = Recorder(windows: [canvasWindow], bounds: canvasBounds)
        rec.start()
        await pause(0.4)
        keys.addViewSubview(["command", "shift", "4"])
        await pause(1.0)
        keys.addViewSubview(["control", "option", "right"])
        await pause(1.0)
        keys.addViewSubview(["command", "click"])
        await pause(3.8)
        rec.stop("feature-keyboard.gif")
    }

    // MARK: Drawing + palette
    func drawingScene() async {
        clearOverlays()
        settings.drawingHoldTime = 30
        settings.temporaryDrawingColor = nil
        let draw = DrawView(frame: canvas.bounds)
        canvas.addSubview(draw)
        bringCursorToFront()

        let rec = Recorder(windows: [canvasWindow], bounds: canvasBounds)
        rec.start()

        // Freehand loop around the last bar
        let center = CGPoint(x: 392, y: 300)
        func loop(_ t: Double) -> CGPoint {
            let a = Double.pi * 0.6 + t * 2.1 * Double.pi
            return CGPoint(x: center.x + 48 * cos(a) + 3 * sin(9 * a), y: center.y + 62 * sin(a))
        }
        showCursor(at: loop(0))
        await pause(0.4)
        draw.startStroke(.freehand, at: loop(0))
        for i in 1...60 {
            let p = loop(Double(i) / 60)
            draw.continueStroke(to: p); showCursor(at: p)
            await pause(1 / 60)
        }
        draw.finishDrawing()
        await pause(0.4)

        // Straight line under the title
        var a = CGPoint(x: 80, y: 392)
        await glide(from: loop(1), to: a, duration: 0.6) { self.showCursor(at: $0) }
        draw.startStroke(.line, at: a)
        await glide(from: a, to: CGPoint(x: 330, y: 392), duration: 0.6) { draw.continueStroke(to: $0); self.showCursor(at: $0) }
        draw.finishDrawing()
        await pause(0.4)

        // Arrow from the notes to the small print
        a = CGPoint(x: 660, y: 130)
        await glide(from: CGPoint(x: 330, y: 392), to: a, duration: 0.6) { self.showCursor(at: $0) }
        draw.startStroke(.arrow, at: a)
        await glide(from: a, to: CGPoint(x: 600, y: 245), duration: 0.6) { draw.continueStroke(to: $0); self.showCursor(at: $0) }
        draw.finishDrawing()
        await pause(0.6)

        // Palette: pick 2 (yellow)
        let at = CGPoint(x: canvasWindow.frame.minX + 600, y: canvasWindow.frame.minY + 245)
        let colors = settings.activePaletteColors
        let palette = ColorPalettePanel(colors: colors, selected: 0, near: at)
        palette.appearance = NSAppearance(named: .aqua)
        // Shown without becoming key: in this harness it would lose key status at once and close itself
        palette.orderFrontRegardless()
        // Front to back
        rec.windows = [palette, canvasWindow]
        await pause(1.4)
        palette.close()
        rec.windows = [canvasWindow]
        settings.temporaryDrawingColor = colors[1]
        await pause(0.3)

        // Yellow freehand underline of the notes
        a = CGPoint(x: 500, y: 312)
        await glide(from: CGPoint(x: 600, y: 245), to: a, duration: 0.5) { self.showCursor(at: $0) }
        draw.startStroke(.freehand, at: a)
        for i in 1...40 {
            let x = 500 + Double(i) * 1.6
            let p = CGPoint(x: x, y: 312 + 3 * sin(Double(i) / 3))
            draw.continueStroke(to: p); showCursor(at: p)
            await pause(1 / 60)
        }
        draw.finishDrawing()
        await pause(1.6)
        draw.clearAll()
        await pause(1.0)
        rec.stop("feature-drawing.gif")
        settings.temporaryDrawingColor = nil
    }

    // MARK: Spotlight
    func spotlightScene() async {
        clearOverlays()
        let spot = SpotlightView(frame: canvas.bounds)
        canvas.addSubview(spot)
        bringCursorToFront()
        var p = CGPoint(x: 200, y: 260)
        spot.move(to: p); showCursor(at: p)
        let rec = Recorder(windows: [canvasWindow], bounds: canvasBounds)
        rec.start()
        await pause(0.5)
        for target in [CGPoint(x: 392, y: 300), CGPoint(x: 620, y: 270), CGPoint(x: 200, y: 400)] {
            await glide(from: p, to: target, duration: 1.1) { spot.move(to: $0); self.showCursor(at: $0) }
            p = target
            await pause(0.6)
        }
        rec.stop("feature-spotlight.gif")
    }

    // MARK: Zoom (the real ZoomView, fed with a picture of the canvas instead of a display capture)
    func zoomScene() async {
        clearOverlays()
        cursor.isHidden = true
        await pause(0.2)
        guard let picture = capture([canvasWindow], best: true) else { return }
        let zoom = ZoomView(frame: canvas.bounds)
        canvas.addSubview(zoom)
        let pictureLayer = zoom.layer!.sublayers![0].sublayers![0]
        pictureLayer.contents = picture
        bringCursorToFront()
        var p = CGPoint(x: 560, y: 340)
        zoom.move(to: p); showCursor(at: p)
        let rec = Recorder(windows: [canvasWindow], bounds: canvasBounds)
        rec.start()
        await pause(0.5)
        for target in [CGPoint(x: 600, y: 290), CGPoint(x: 640, y: 250), CGPoint(x: 420, y: 330)] {
            await glide(from: p, to: target, duration: 1.2) { zoom.move(to: $0); self.showCursor(at: $0) }
            p = target
            await pause(0.6)
        }
        rec.stop("feature-zoom.gif")
    }

    // MARK: Settings: 5 tabs + the Animation Durations panel, composed 3×2
    func settingsGrid(dark: Bool) async {
        NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let controller = SettingsWindowController()
        controller.showWindow(nil)
        let window = controller.window!
        window.orderFrontRegardless()
        let tabView = window.contentView!.subviews.compactMap { $0 as? NSTabView }.first!
        var tiles: [CGImage] = []
        for index in 0..<tabView.numberOfTabViewItems {
            tabView.selectTabViewItem(at: index)
            await pause(0.4)
            if let image = capture([window], best: true) { tiles.append(image) }
        }
        // Animation Durations open, on the General tab: the whole (taller) window, scaled to fit the tile
        tabView.selectTabViewItem(at: 4)
        let disclosure = window.contentView!.subviews.compactMap { $0 as? NSButton }.first { $0.bezelStyle == .disclosure }!
        disclosure.performClick(nil)
        await pause(0.5)
        if let image = capture([window], best: true), let first = tiles.first {
            let scale = min(CGFloat(first.width) / CGFloat(image.width), CGFloat(first.height) / CGFloat(image.height))
            let w = CGFloat(image.width) * scale, h = CGFloat(image.height) * scale
            let ctx = CGContext(data: nil, width: first.width, height: first.height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.interpolationQuality = .high
            ctx.draw(image, in: CGRect(x: (CGFloat(first.width) - w) / 2, y: 0, width: w, height: h))
            if let tile = ctx.makeImage() { tiles.append(tile) }
        }
        window.close()

        // 3 columns × 2 rows on a transparent background, soft shadows
        let w = tiles[0].width, h = tiles[0].height
        let gap = Int(40 * CGFloat(w) / 600 / 2) * 2, margin = gap
        let width = margin * 2 + w * 3 + gap * 2, height = margin * 2 + h * 2 + gap
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 30, color: NSColor.black.withAlphaComponent(dark ? 0.6 : 0.25).cgColor)
        for (i, tile) in tiles.prefix(6).enumerated() {
            let col = i % 3, row = i / 3
            let x = margin + col * (w + gap)
            let y = height - margin - h - row * (h + gap)
            ctx.draw(tile, in: CGRect(x: x, y: y, width: tile.width, height: tile.height))
        }
        writePNG(ctx.makeImage()!, dark ? "settings-dark.png" : "settings-light.png")
    }

    func run() async {
        // Fresh defaults in this harness's own domain: the shots show the default settings
        settings.resetToDefaults()
        makeCanvas()
        await pause(0.5)
        // Optional second argument: run only that scene
        let only = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
        if only == nil || only == "mouse" { await mouseScene() }
        if only == nil || only == "keyboard" { await keyboardScene() }
        if only == nil || only == "drawing" { await drawingScene() }
        if only == nil || only == "spotlight" { await spotlightScene() }
        if only == nil || only == "zoom" { await zoomScene() }
        canvasWindow.close()
        if only == nil || only == "settings" {
            // The scenes changed some values (drawing hold time); the shots show the defaults
            settings.resetToDefaults()
            await settingsGrid(dark: false)
            await settingsGrid(dark: true)
        }
        settings.resetToDefaults()
        NSApp.terminate(nil)
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let harness = Harness()
    Task { @MainActor in await harness.run() }
    app.run()
}
