//
//  ViewController.swift
//  DaemonStraight
//
//  Main view controller handling all presentation assistant features
//

import Cocoa
import QuartzCore

class ViewController: NSViewController {

    // MARK: - Properties
    private var drawView: DrawView?
    private var shortcutsView: ShortcutPressedViewContainer?
    private var mouseCircleView: CircleView?
    private let settings = SettingsManager.shared

    // State flags
    var drawingIsOn: Bool = false
    var mouseIsOn: Bool = false  // Start with mouse highlighting OFF
    var shortcutsCatchIsOn: Bool = false  // Start with keyboard display OFF

    // Modes
    var mouseHighlightMode: Bool = false  // Start with mouse highlighting OFF
    var drawingMode: Bool = false
    var shortcutCatcherMode: Bool = false  // Start with keyboard display OFF

    // Timing
    var drawingDisapperaTimer: Timer?
    var mouseLocation: CGPoint = .zero
    var mousePath: NSBezierPath?
    var mouseUpdateCount: Int = 0  // For periodic logging

    // Event monitors
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var mouseMonitor: Any?
    private var flagsMonitor: Any?
    private var mouseTrackingTimer: Timer?

    // Keyboard tracking
    private var shortcutsPressed: [String] = []
    private var shortcutPressTime: Date?

    // Drawing state tracking
    private var isShiftPressed: Bool = false
    private var isControlPressed: Bool = false
    private var isCommandPressed: Bool = false
    private var isOptionPressed: Bool = false
    private var isCapsLockPressed: Bool = false
    private var isDrawingActive: Bool = false

    // Screen size
    private var screenSize: CGSize = .zero

    // MARK: - Initialization
    init(screenSize: CGSize) {
        self.screenSize = screenSize
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // CRITICAL: Create view with correct screen size BEFORE viewDidLoad
    override func loadView() {
        let mainView = NSView(frame: NSRect(origin: .zero, size: screenSize))
        mainView.wantsLayer = true
        self.view = mainView
        NSLog("🎨 [ViewController] loadView() - Created view with size: \(NSStringFromSize(screenSize))")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("🎨 [ViewController] viewDidLoad() - Initializing...")
        setupUI()
        setupEventMonitors()
        startMouseTracking()
        NSLog("✅ [ViewController] Initialization complete")
        NSLog("🖱️  [ViewController] Mouse highlighting: \(mouseIsOn ? "ON" : "OFF")")
        NSLog("⌨️  [ViewController] Keyboard display: \(shortcutsCatchIsOn ? "ON" : "OFF")")
        NSLog("✏️  [ViewController] Drawing mode: \(drawingIsOn ? "ON" : "OFF")")
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        NSLog("👁️  [ViewController] viewDidAppear() - View is now visible")
    }

    deinit {
        NSLog("🗑️  [ViewController] deinit - Cleaning up...")
        removeEventMonitors()
        mouseTrackingTimer?.invalidate()
    }

    // MARK: - UI Setup
    private func setupUI() {
        NSLog("🎨 [ViewController] Setting up UI components...")
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        // CRITICAL: Make view explicitly want to draw
        view.layer?.isOpaque = false
        view.layerContentsRedrawPolicy = .onSetNeedsDisplay

        // CRITICAL: Ensure layer doesn't clip subviews/sublayers
        view.layer?.masksToBounds = false

        NSLog("  📐 View frame: \(NSStringFromRect(view.frame))")
        NSLog("  📐 View bounds: \(NSStringFromRect(view.bounds))")

        // Setup drawing view
        let drawingView = DrawView(frame: view.bounds)
        drawingView.autoresizingMask = [.width, .height]
        drawingView.wantsLayer = true
        view.addSubview(drawingView)
        drawView = drawingView
        NSLog("  ✅ Drawing view added")

        // Setup shortcuts display container
        let shortcutsContainer = ShortcutPressedViewContainer(frame: view.bounds)
        shortcutsContainer.autoresizingMask = [.width, .height]
        shortcutsContainer.wantsLayer = true
        view.addSubview(shortcutsContainer)
        shortcutsView = shortcutsContainer
        NSLog("  ✅ Shortcuts container added - frame: \(NSStringFromRect(shortcutsContainer.frame))")

        // Setup mouse highlight circle (initially visible since mouseIsOn = true)
        let circle = CircleView(frame: NSRect(x: 100, y: 100, width: 150, height: 150))  // Start at visible position
        circle.wantsLayer = true
        circle.layer?.isOpaque = false
        circle.isHidden = !mouseIsOn  // Show if mouse highlighting is on
        circle.alphaValue = 1.0  // Fully opaque
        view.addSubview(circle, positioned: .above, relativeTo: nil)  // Ensure it's on top
        mouseCircleView = circle
        NSLog("  ✅ Mouse circle view added at (100, 100), hidden: \(!mouseIsOn), size: 150x150")
        NSLog("  👁️  Circle superview: \(circle.superview != nil), window: \(circle.window != nil)")
    }

    // MARK: - Event Monitoring
    private func setupEventMonitors() {
        NSLog("👂 [ViewController] Setting up GLOBAL event monitors (work regardless of app focus)...")

        // GLOBAL key event monitor - works system-wide even when app isn't focused
        localEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        NSLog("  ✅ Global key event monitor added")

        // GLOBAL mouse event monitor for clicks and movement
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .mouseMoved]) { [weak self] event in
            self?.handleMouseEvent(event)
        }
        NSLog("  ✅ Global mouse event monitor added")

        // GLOBAL mouse drag monitor for drawing
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp, .rightMouseUp]) { [weak self] event in
            self?.handleMouseEvent(event)
        }
        NSLog("  ✅ Global mouse drag monitor added")

        // GLOBAL modifier key monitor
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        NSLog("  ✅ Global modifier key monitor added")
        NSLog("⚠️  [ViewController] All monitors are GLOBAL - require accessibility permissions!")
    }

    private func startMouseTracking() {
        NSLog("🖱️  [ViewController] Starting mouse tracking timer (60fps)...")
        // Start a timer to continuously update mouse position
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateMousePosition()
        }
        NSLog("✅ [ViewController] Mouse tracking timer started")
    }

    private func updateMousePosition() {
        let location = NSEvent.mouseLocation

        // Update mouse highlighting if enabled
        if mouseIsOn {
            updateMouseHighlight(at: location)
        }

        // Update drawing if shift is pressed and drawing mode is enabled
        if drawingIsOn && isDrawingActive && isShiftPressed {
            let viewPoint = convertScreenToView(location)

            if isControlPressed {
                // Update straight line endpoint
                drawView?.updateStraightLineEndpoint(to: viewPoint)
            } else {
                // Continue freehand drawing
                drawView?.continueFreehandDrawing(to: viewPoint)
            }
        }
    }

    private func removeEventMonitors() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Event Handlers

    // Map keyCode to English character (language-agnostic)
    private func keyCodeToEnglishChar(_ keyCode: UInt16) -> String? {
        switch keyCode {
        // Letters
        case 0: return "a"
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 4: return "h"
        case 5: return "g"
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 16: return "y"
        case 17: return "t"
        case 31: return "o"
        case 32: return "u"
        case 34: return "i"
        case 35: return "p"
        case 37: return "l"
        case 38: return "j"
        case 40: return "k"
        case 45: return "n"
        case 46: return "m"

        // Numbers
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"

        // Special keys
        case 36: return "\r"  // Return
        case 48: return "\t"  // Tab
        case 49: return " "   // Space
        case 51: return "\u{7F}"  // Delete
        case 53: return "\u{1B}"  // Escape

        // Arrow keys
        case 123: return "\u{F702}"  // Left
        case 124: return "\u{F703}"  // Right
        case 125: return "\u{F701}"  // Down
        case 126: return "\u{F700}"  // Up

        // Function keys
        case 122: return "\u{F704}"  // F1
        case 120: return "\u{F705}"  // F2
        case 99: return "\u{F706}"   // F3
        case 118: return "\u{F707}"  // F4
        case 96: return "\u{F708}"   // F5
        case 97: return "\u{F709}"   // F6
        case 98: return "\u{F70A}"   // F7
        case 100: return "\u{F70B}"  // F8
        case 101: return "\u{F70C}"  // F9
        case 109: return "\u{F70D}"  // F10
        case 103: return "\u{F70E}"  // F11
        case 111: return "\u{F70F}"  // F12

        default: return nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard shortcutsCatchIsOn else { return }

        if event.type == .keyDown {
            // Use keyCode for language-agnostic character detection
            let keyCode = event.keyCode

            // Get English character from keyCode
            if let englishChar = keyCodeToEnglishChar(keyCode) {
                handleKeyDown(englishChar, modifiers: event.modifierFlags)
            } else {
                // Fallback to original characters if keyCode not mapped
                if let characters = event.charactersIgnoringModifiers {
                    handleKeyDown(characters, modifiers: event.modifierFlags)
                }
            }
        } else if event.type == .keyUp {
            clearShortcutsIfNeeded()
        }
    }

    private func handleKeyDown(_ key: String, modifiers: NSEvent.ModifierFlags) {
        // Check if we have meaningful modifiers (command, option, control - NOT just shift)
        let hasCommand = modifiers.contains(.command)
        let hasOption = modifiers.contains(.option)
        let hasControl = modifiers.contains(.control)
        let hasShift = modifiers.contains(.shift)
        let hasFunction = modifiers.contains(.function)  // fn key

        let hasMeaningfulModifier = hasCommand || hasOption || hasControl || hasFunction

        // Determine key type for filtering
        let fKeys = [
            "\u{F704}", "\u{F705}", "\u{F706}", "\u{F707}", "\u{F708}",
            "\u{F709}", "\u{F70A}", "\u{F70B}", "\u{F70C}", "\u{F70D}",
            "\u{F70E}", "\u{F70F}", "\u{F710}", "\u{F711}", "\u{F712}",
            "\u{F713}", "\u{F714}", "\u{F715}", "\u{F716}", "\u{F717}"
        ]

        let isFunctionKey = fKeys.contains(key) ||
                           (key.count >= 2 && key.count <= 3 &&
                            key.lowercased().hasPrefix("f") &&
                            key.dropFirst().allSatisfy { $0.isNumber })

        let specialChars = [
            "\u{1B}", "\t", "\r", "\u{7F}", "\u{F728}",
            "\u{F700}", "\u{F701}", "\u{F702}", "\u{F703}"
        ]
        let specialKeyNames = ["escape", "esc", "tab", "return", "enter", "delete", "fn"]
        let isSpecialKey = specialChars.contains(key) || specialKeyNames.contains(key.lowercased())

        // Always skip space bar
        if key == " " {
            return
        }

        let alphanumericChars = "abcdefghijklmnopqrstuvwxyz0123456789"
        let isAlphanumeric = key.count == 1 && alphanumericChars.contains(key.lowercased())

        // Apply settings-based filtering
        if isFunctionKey && !settings.showFunctionKeys {
            return
        }

        if isSpecialKey && !settings.showSpecialKeys {
            return
        }

        // Filter logic:
        // 1. Shortcuts with meaningful modifiers, special and function keys - show
        // 2. Plain typing (with or without shift) - show only letters/digits, and only if enabled in settings

        if !hasMeaningfulModifier && !isSpecialKey && !isFunctionKey {
            guard isAlphanumeric && settings.showAlphanumericKeys else { return }
        }

        var keys: [String] = []

        // Add modifiers in order (only if modifier keys are enabled in settings)
        if settings.showModifierKeys {
            if hasFunction {
                keys.append("fn")
            }
            if hasControl {
                keys.append("control")
            }
            if hasOption {
                keys.append("option")
            }
            if hasCommand {
                keys.append("command")
            }
            if hasShift && hasMeaningfulModifier {
                // Only show shift if accompanied by other modifiers
                keys.append("shift")
            }
        }

        // Add the actual key
        keys.append(key)

        shortcutsPressed = keys
        shortcutPressTime = Date()

        // Display the shortcut
        shortcutsView?.addViewSubview(keys)
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        // Handle modifier key changes
        let flags = event.modifierFlags

        // Track modifier states
        let wasShiftPressed = isShiftPressed
        let wasControlPressed = isControlPressed
        let wasCommandPressed = isCommandPressed
        let wasOptionPressed = isOptionPressed
        let wasCapsLockPressed = isCapsLockPressed

        isShiftPressed = flags.contains(.shift)
        isControlPressed = flags.contains(.control)
        isCommandPressed = flags.contains(.command)
        isOptionPressed = flags.contains(.option)
        isCapsLockPressed = flags.contains(.capsLock)

        // Handle drawing mode when it's enabled
        if drawingIsOn {
            handleDrawingModifierChanges(
                wasShift: wasShiftPressed,
                wasControl: wasControlPressed,
                wasCommand: wasCommandPressed,
                wasOption: wasOptionPressed,
                wasCapsLock: wasCapsLockPressed
            )
        }

        // Clear shortcuts display if no modifiers
        if !flags.contains(.command) && !flags.contains(.option) &&
           !flags.contains(.control) && !flags.contains(.shift) && !flags.contains(.function) {
            clearShortcutsIfNeeded()
        }
    }

    private func handleDrawingModifierChanges(wasShift: Bool, wasControl: Bool, wasCommand: Bool, wasOption: Bool, wasCapsLock: Bool) {
        // Detect shift press/release for drawing
        if isShiftPressed && !wasShift {
            // Shift just pressed - start drawing at current mouse position
            let mouseLocation = NSEvent.mouseLocation
            let viewPoint = convertScreenToView(mouseLocation)

            if isControlPressed {
                // ctrl+shift → straight line mode
                drawView?.startStraightLineDrawing(at: viewPoint)
                isDrawingActive = true
            } else {
                // shift only → freehand mode
                drawView?.startFreehandDrawing(at: viewPoint)
                isDrawingActive = true
            }
        } else if !isShiftPressed && wasShift {
            // Shift just released - finish drawing and start countdown
            if isDrawingActive {
                drawView?.finishDrawing()
                isDrawingActive = false
            }
        } else if isShiftPressed && isControlPressed && !wasControl {
            // Control pressed while shift is held - switch to straight line mode
            if isDrawingActive {
                let mouseLocation = NSEvent.mouseLocation
                let viewPoint = convertScreenToView(mouseLocation)
                drawView?.switchToStraightLineMode(at: viewPoint)
            }
        } else if isShiftPressed && !isControlPressed && wasControl {
            // Control released while shift is held - switch to freehand mode
            if isDrawingActive {
                let mouseLocation = NSEvent.mouseLocation
                let viewPoint = convertScreenToView(mouseLocation)
                drawView?.switchToFreehandMode(at: viewPoint)
            }
        }

        // Handle countdown pause/resume based on ALL modifier keys (command, option, control, caps lock)
        if !isDrawingActive {
            // Only manage countdown when not actively drawing
            let hadModifier = wasCommand || wasOption || wasControl || wasCapsLock
            let hasModifier = isCommandPressed || isOptionPressed || isControlPressed || isCapsLockPressed

            if hasModifier && !hadModifier {
                // Modifier just pressed - pause countdown
                drawView?.pauseDisappearanceCountdown()
            } else if !hasModifier && hadModifier {
                // Modifier just released - resume countdown
                drawView?.resumeDisappearanceCountdown()
            }
        }
    }

    private func convertScreenToView(_ screenPoint: CGPoint) -> CGPoint {
        // NSEvent.mouseLocation is already in screen coordinates
        // Our view also uses screen coordinates, so return as-is
        return screenPoint
    }

    private func clearShortcutsIfNeeded() {
        if let pressTime = shortcutPressTime {
            let elapsed = Date().timeIntervalSince(pressTime)
            if elapsed > 0.1 { // Debounce
                shortcutsPressed.removeAll()
                shortcutPressTime = nil
            }
        }
    }

    private func handleMouseEvent(_ event: NSEvent) {
        let location = NSEvent.mouseLocation

        switch event.type {
        case .mouseMoved:
            updateMouseHighlight(at: location)

        case .leftMouseDown:
            // Start continuous shrink animation with left click color
            mouseCircleView?.startShrinking(color: settings.mouseLeftClickColor)

        case .rightMouseDown:
            // Start continuous shrink animation with right click color
            mouseCircleView?.startShrinking(color: settings.mouseRightClickColor)

        case .leftMouseUp, .rightMouseUp:
            // Stop shrinking and expand back when button released
            mouseCircleView?.stopShrinking()

        default:
            break
        }
    }

    // MARK: - Mouse Highlight
    private func updateMouseHighlight(at location: CGPoint) {
        guard mouseIsOn else { return }

        // Convert screen coordinates to view coordinates
        guard let window = view.window,
              window.screen != nil else {
            NSLog("⚠️ [Mouse] No window or screen available!")
            return
        }

        guard let circle = mouseCircleView else {
            NSLog("⚠️ [Mouse] Mouse circle view is nil!")
            return
        }

        // NSEvent.mouseLocation is already in screen coordinates with origin at bottom-left
        // Our view also has origin at bottom-left, so coordinates match directly
        let newOrigin = CGPoint(
            x: location.x - 75,  // Center the 150x150 circle
            y: location.y - 75   // Y coordinate is correct as-is
        )

        // Update frame using CATransaction to avoid animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        circle.frame.origin = newOrigin
        CATransaction.commit()

        circle.isHidden = false
        circle.layer?.isHidden = false  // Ensure layer is also not hidden
    }


    // MARK: - Public Controls
    func toggleDrawingMode() {
        drawingIsOn.toggle()
        drawingMode = drawingIsOn

        if !drawingIsOn {
            // Cancel any active drawing and clear all paths
            isDrawingActive = false
            drawView?.clearAll()
        }
    }

    func toggleMouseHighlight() {
        mouseIsOn.toggle()
        mouseHighlightMode = mouseIsOn

        if !mouseIsOn {
            mouseCircleView?.isHidden = true
        } else {
            mouseCircleView?.isHidden = false
        }
    }

    func toggleShortcutCatcher() {
        shortcutsCatchIsOn.toggle()
        shortcutCatcherMode = shortcutsCatchIsOn

        if !shortcutsCatchIsOn {
            shortcutsView?.clearAll()
        }
    }

    func clearDrawing() {
        isDrawingActive = false
        drawView?.clearAll()
    }

    // MARK: - Mouse Tracking Control
    func pauseMouseTracking() {
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
    }

    func resumeMouseTracking() {
        // Only resume if not already running
        guard mouseTrackingTimer == nil else { return }
        startMouseTracking()
    }
}
