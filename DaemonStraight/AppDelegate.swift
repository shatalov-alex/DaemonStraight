//
//  AppDelegate.swift
//  DaemonStraight
//
//  Menu bar only application with global keyboard shortcuts
//

import Cocoa

// Note: @main removed - using explicit main.swift instead
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    // MARK: - Properties
    private var statusItem: NSStatusItem!
    private var mouseItem: NSMenuItem!
    private var keyboardItem: NSMenuItem!
    private var drawingItem: NSMenuItem!
    private var spotlightItem: NSMenuItem!
    private var zoomItem: NSMenuItem!
    private var allFeaturesItem: NSMenuItem!
    private var updatesItem: NSMenuItem!
    private var accessibilityItem: NSMenuItem!
    private var accessibilityTimer: Timer?
    // The last other app that was active: focus goes back to it if this app gets activated for nothing
    private var previousApp: NSRunningApplication?
    // Set right before this app activates itself to show a window
    private var activatingForWindow = false
    // One click-through overlay per display; each controller draws its own part of the screen
    private var overlays: [(window: NSWindow, controller: ViewController)] = []
    private var settingsWindowController: SettingsWindowController?
    private let settings = SettingsManager.shared
    private let updateManager = UpdateManager()

    // Keyboard shortcut monitors
    private var localHotkeyMonitor: Any?
    private var globalHotkeyMonitor: Any?
    private var windowMaintenanceTimer: Timer?

    // MARK: - Application Lifecycle
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("🚀 [AppDelegate] Application starting...")

        // Setup menu bar
        setupMenuBar()
        NSLog("✅ [AppDelegate] Menu bar setup complete")

        // Request accessibility permissions
        checkAccessibilityPermissions()

        // Give the focus back if the app gets activated without a window to show
        setupFocusReturn()

        // Setup overlay windows (one per display) and rebuild them when displays change
        setupOverlayWindows()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSLog("✅ [AppDelegate] Overlay windows setup complete")

        // Turn on the features selected in Settings › General (all off by default)
        setFeatures(mouse: settings.launchWithMouse,
                    keyboard: settings.launchWithKeyboard,
                    drawing: settings.launchWithDrawing,
                    spotlight: settings.launchWithSpotlight)

        // Setup global keyboard shortcuts
        setupGlobalKeyboardShortcuts()
        NSLog("✅ [AppDelegate] Global keyboard shortcuts setup complete")

        // Setup window maintenance timer
        setupWindowMaintenance()

        // Check for updates if the user agreed to it
        setupUpdateChecks()

        NSLog("🎉 [AppDelegate] Application ready!")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NSLog("🛑 [AppDelegate] Application terminating...")
        if let monitor = localHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        windowMaintenanceTimer?.invalidate()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - Permissions
    // Only the system's own prompt: a window of this app would take the focus from the app the
    // presenter is in. Until the permission is granted, the menu offers to open the setting and the
    // app checks every second, so it starts working without a restart
    private func checkAccessibilityPermissions() {
        NSLog("🔐 [Permissions] Checking accessibility permissions...")

        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        if AXIsProcessTrustedWithOptions(options) {
            NSLog("✅ [Permissions] Accessibility permissions GRANTED")
            return
        }

        NSLog("⚠️  [Permissions] Accessibility permissions NOT granted, waiting for them")
        accessibilityItem.isHidden = false
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard AXIsProcessTrusted() else { return }
            timer.invalidate()
            self?.accessibilityGranted()
        }
    }

    private func accessibilityGranted() {
        NSLog("✅ [Permissions] Accessibility permissions GRANTED, restarting the event monitors")
        accessibilityTimer = nil
        accessibilityItem.isHidden = true
        // Monitors added without the permission may stay deaf, so add them again
        setupGlobalKeyboardShortcuts()
        screensChanged()
    }

    @objc private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Focus
    // Opening the app from Shortcuts or Spotlight activates it although it has nothing to show. An active
    // app without a window gets the key presses: macOS beeps, and the global monitors (which only see
    // other apps' events) miss them. So the focus goes straight back to the app the presenter was in
    private func setupFocusReturn() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
            MainActor.assumeIsolated { self?.previousApp = app }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationBecameActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: nil
        )
        // Opened from Shortcuts, the app may be active already
        DispatchQueue.main.async { [weak self] in
            if NSApp.isActive { self?.applicationBecameActive() }
        }
    }

    @objc private func applicationBecameActive() {
        if activatingForWindow {
            activatingForWindow = false
            return
        }
        returnFocusIfNoWindow()
    }

    // Also when the last window of this app (Settings, an alert) closes
    @objc private func windowWillClose(_ notification: Notification) {
        guard !(notification.object is TransparentOverlayWindow) else { return }
        returnFocusIfNoWindow()
    }

    private func returnFocusIfNoWindow() {
        // Let a window that is being opened or closed settle first
        DispatchQueue.main.async { [weak self] in
            guard let self, NSApp.isActive, NSApp.modalWindow == nil else { return }
            let showsWindow = NSApp.windows.contains {
                !($0 is TransparentOverlayWindow) && $0.isVisible && $0.canBecomeKey
            }
            guard !showsWindow else { return }
            self.returnFocus()
        }
    }

    private func returnFocus() {
        if let app = previousApp, !app.isTerminated {
            NSLog("↩️  [Focus] Activated without a window, returning the focus to the previous app")
            if #available(macOS 14.0, *) {
                NSApp.yieldActivation(to: app)
                app.activate()
            } else {
                app.activate(options: [])
            }
        } else {
            NSLog("↩️  [Focus] Activated without a window, hiding")
            NSApp.hide(nil)  // the next app gets the focus; the overlays can't hide
        }
    }

    // For this app's own windows (Settings, alerts, updates)
    private func activateForWindow() {
        if !NSApp.isActive {
            activatingForWindow = true
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Updates
    private func setupUpdateChecks() {
        updateManager.onAvailableVersionChanged = { [weak self] version in
            self?.showAvailableUpdate(version)
        }

        if !settings.hasChosenUpdateChecks {
            askAboutUpdateChecks()
        }
        if settings.checkForUpdatesAtLaunch {
            updateManager.checkInBackground()
        }
    }

    private func askAboutUpdateChecks() {
        let alert = NSAlert()
        alert.messageText = "Check for Updates When the App Starts?"
        alert.informativeText = "DaemonStraight can check GitHub for a new version each time it starts. Nothing is downloaded or installed unless you confirm it.\n\nYou can change this later in Settings > General."
        alert.addButton(withTitle: "Check at Start")
        alert.addButton(withTitle: "Don't Check")

        activateForWindow()
        settings.checkForUpdatesAtLaunch = alert.runModal() == .alertFirstButtonReturn
        returnFocusIfNoWindow()
    }

    // A quiet hint in the menu bar: an update window must not appear during a presentation
    private func showAvailableUpdate(_ version: String?) {
        let symbol = version == nil ? "display" : "arrow.down.circle"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "DaemonStraight")
        statusItem.button?.image?.isTemplate = true
        updatesItem.title = version.map { "Update to \($0)..." } ?? "Check for Updates..."
    }

    @objc private func checkForUpdates() {
        activateForWindow()
        updateManager.checkForUpdates()
    }

    // MARK: - Menu Bar Setup
    private func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Use simple built-in SF Symbol for monitor/presentation
            button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "DaemonStraight")
            button.image?.isTemplate = true
        }

        // Create simple menu
        let menu = NSMenu()
        menu.delegate = self  // Set delegate to detect menu open/close

        // App name header (disabled/inactive)
        let headerItem = NSMenuItem(title: "DaemonStraight", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // Shown only while the Accessibility permission is missing
        accessibilityItem = NSMenuItem(title: "Allow Accessibility Access...", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        accessibilityItem.target = self
        accessibilityItem.isHidden = true
        menu.addItem(accessibilityItem)

        menu.addItem(NSMenuItem.separator())

        // Feature toggles (states are updated in updateMenuItemStates)
        mouseItem = NSMenuItem(title: "Mouse Highlighting", action: #selector(toggleMouseHighlight), keyEquivalent: "")
        mouseItem.target = self
        menu.addItem(mouseItem)

        keyboardItem = NSMenuItem(title: "Keyboard Display", action: #selector(toggleKeyboardDisplay), keyEquivalent: "")
        keyboardItem.target = self
        menu.addItem(keyboardItem)

        drawingItem = NSMenuItem(title: "Drawing Mode", action: #selector(toggleDrawingMode), keyEquivalent: "")
        drawingItem.target = self
        menu.addItem(drawingItem)

        spotlightItem = NSMenuItem(title: "Spotlight", action: #selector(toggleSpotlight), keyEquivalent: "")
        spotlightItem.target = self
        menu.addItem(spotlightItem)

        zoomItem = NSMenuItem(title: "Zoom", action: #selector(toggleZoom), keyEquivalent: "")
        zoomItem.target = self
        menu.addItem(zoomItem)

        menu.addItem(NSMenuItem.separator())

        allFeaturesItem = NSMenuItem(title: "Turn All On", action: #selector(toggleAllFeatures), keyEquivalent: "")
        allFeaturesItem.target = self
        menu.addItem(allFeaturesItem)

        menu.addItem(NSMenuItem.separator())

        // Clear Drawing
        let clearItem = NSMenuItem(title: "Clear Drawing", action: #selector(clearDrawing), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        let undoItem = NSMenuItem(title: "Undo Last Stroke", action: #selector(undoLastStroke), keyEquivalent: "")
        undoItem.target = self
        menu.addItem(undoItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Updates
        updatesItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updatesItem.target = self
        menu.addItem(updatesItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")

        statusItem.menu = menu
    }

    // MARK: - Overlay Window Setup
    private func setupOverlayWindows() {
        for screen in NSScreen.screens {
            overlays.append(createOverlay(for: screen))
        }
        NSLog("🪟 [Window] Created \(overlays.count) overlay window(s)")
    }

    private func createOverlay(for screen: NSScreen) -> (window: NSWindow, controller: ViewController) {
        // Fullscreen window covering the entire display including the menu bar
        let frame = screen.frame

        // Create custom overlay window that never becomes key
        let window = TransparentOverlayWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        // The init above treats contentRect as relative to the screen - set the global frame explicitly
        window.setFrame(frame, display: false)
        window.isReleasedWhenClosed = false

        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false

        // Use the highest possible window level for overlays
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))

        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true  // Always click-through
        window.acceptsMouseMovedEvents = true
        window.canHide = false  // stays visible when the app hides to give the focus back
        window.alphaValue = 1.0  // Keep fully visible

        // Create view controller with screen size
        let controller = ViewController(screenSize: frame.size)
        window.contentViewController = controller

        // Ensure autoresizing works
        controller.view.autoresizingMask = [.width, .height]
        window.contentView?.autoresizingMask = [.width, .height]

        // Show window - use orderFrontRegardless to keep it visible
        window.orderFrontRegardless()

        NSLog("🪟 [Window] Overlay for display \(NSStringFromRect(frame)) at level \(window.level.rawValue)")
        return (window, controller)
    }

    @objc private func screensChanged() {
        // Displays were connected, disconnected or rearranged: rebuild the overlays, keeping the modes
        let current = overlays.first?.controller
        let mouseOn = current?.mouseIsOn ?? false
        let keyboardOn = current?.shortcutsCatchIsOn ?? false
        let drawingOn = current?.drawingIsOn ?? false
        let spotlightOn = current?.spotlightIsOn ?? false
        let zoomOn = current?.zoomIsOn ?? false

        for overlay in overlays {
            if overlay.controller.zoomIsOn { overlay.controller.toggleZoom() }  // stops its capture
            overlay.window.orderOut(nil)
            overlay.window.contentViewController = nil
            overlay.window.close()
        }
        overlays.removeAll()
        setupOverlayWindows()

        setFeatures(mouse: mouseOn, keyboard: keyboardOn, drawing: drawingOn, spotlight: spotlightOn)
        if zoomOn {
            overlays.forEach { $0.controller.toggleZoom() }
            updateMenuItemStates()
        }
    }

    // MARK: - Global Keyboard Shortcuts
    private func setupGlobalKeyboardShortcuts() {
        NSLog("⌨️  [Shortcuts] Setting up global keyboard shortcut monitoring...")

        [localHotkeyMonitor, globalHotkeyMonitor].compactMap { $0 }.forEach { NSEvent.removeMonitor($0) }

        // Local monitor - captures events for this app. A hotkey is used up here: passed on, it would
        // make macOS beep when no window takes it
        localHotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            (self?.handleHotkeyEvent(event) ?? false) ? nil : event
        }

        // Global monitor - captures ALL system events (requires accessibility permissions)
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            _ = self?.handleHotkeyEvent(event)
        }

        NSLog("✅ [Shortcuts] Global keyboard shortcut monitoring active")
        NSLog("🎯 [Shortcuts] Listening for system-wide keyboard events...")
    }

    // Returns whether the event was one of the hotkeys
    private func handleHotkeyEvent(_ event: NSEvent) -> Bool {
        // Don't toggle modes while a new hotkey is being recorded in Settings
        guard !HotkeyRecorderView.isRecordingAny else { return false }

        let modifiers = event.modifierFlags.intersection([.control, .option, .command, .shift])
        let keyCode = event.keyCode

        let actions: [(hotkey: SettingsManager.Hotkey, action: () -> Void)] = [
            (settings.mouseToggleHotkey, { self.toggleMouseHighlight() }),
            (settings.keyboardToggleHotkey, { self.toggleKeyboardDisplay() }),
            (settings.drawingToggleHotkey, { self.toggleDrawingMode() }),
            (settings.spotlightToggleHotkey, { self.toggleSpotlight() }),
            (settings.zoomToggleHotkey, { self.toggleZoom() }),
            (settings.allToggleHotkey, { self.toggleAllFeatures() }),
            (settings.undoDrawingHotkey, { self.undoLastStroke() }),
            (settings.nextDrawingColorHotkey, { self.toggleColorPalette() }),
            (settings.zoomInHotkey, { self.changeMagnificationOrSpotlight(by: 1) }),
            (settings.zoomOutHotkey, { self.changeMagnificationOrSpotlight(by: -1) }),
            (settings.lensLargerHotkey, { self.changeZoomLens(by: 1) }),
            (settings.lensSmallerHotkey, { self.changeZoomLens(by: -1) }),
        ]
        guard let match = actions.first(where: { $0.hotkey.keyCode == keyCode && $0.hotkey.modifiers == modifiers.rawValue }) else {
            return false
        }
        match.action()
        return true
    }

    // MARK: - Sizes and Color While Presenting
    // Saved like the Settings sliders, within the same ranges

    /// Zoom in or out when Zoom is on, otherwise a larger or smaller spotlight
    private func changeMagnificationOrSpotlight(by step: CGFloat) {
        guard let controller = overlays.first?.controller else { return }
        if controller.zoomIsOn {
            settings.zoomMagnification = min(max(settings.zoomMagnification + step * 0.5, 1.5), 4.0)
        } else if controller.spotlightIsOn {
            settings.spotlightDiameter = min(max(settings.spotlightDiameter + step * 50, 150), 800)
        } else {
            return
        }
        settingsChangedByHotkey()
    }

    private func changeZoomLens(by step: CGFloat) {
        guard overlays.first?.controller.zoomIsOn == true else { return }
        settings.zoomDiameter = min(max(settings.zoomDiameter + step * 50, 150), 600)
        settingsChangedByHotkey()
    }

    private var colorPalette: ColorPalettePanel?

    /// Opens the numbered palette, or closes it when it's open
    private func toggleColorPalette() {
        if let palette = colorPalette {
            palette.close()
            return
        }
        let colors = settings.activePaletteColors
        let current = settings.currentDrawingColor
        let palette = ColorPalettePanel(colors: colors, selected: colors.firstIndex { Self.isSameColor($0, current) },
                                        near: NSEvent.mouseLocation)
        palette.onPick = { [weak self] index in
            guard let self, index < colors.count else { return }
            self.setDrawingColor(colors[index])
        }
        palette.onClose = { [weak self, weak palette] in
            if self?.colorPalette === palette {
                self?.colorPalette = nil
            }
        }
        colorPalette = palette
        palette.show()
    }

    /// New strokes use this color; it becomes the Line Color only if the setting says so
    private func setDrawingColor(_ color: NSColor) {
        if settings.rememberDrawingColor {
            settings.temporaryDrawingColor = nil
            settings.drawingColor = color
            settingsChangedByHotkey()
        } else {
            settings.temporaryDrawingColor = color
        }
    }

    private static func isSameColor(_ a: NSColor, _ b: NSColor) -> Bool {
        guard let a = a.usingColorSpace(.sRGB), let b = b.usingColorSpace(.sRGB) else { return false }
        return abs(a.redComponent - b.redComponent) < 0.02 && abs(a.greenComponent - b.greenComponent) < 0.02
            && abs(a.blueComponent - b.blueComponent) < 0.02
    }

    private func settingsChangedByHotkey() {
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        settingsWindowController?.reloadSettings()
    }

    // MARK: - Menu Actions
    @objc private func toggleMouseHighlight() {
        overlays.forEach { $0.controller.toggleMouseHighlight() }
        updateMenuItemStates()
        updateWindowMouseEventHandling()
    }

    @objc private func toggleKeyboardDisplay() {
        overlays.forEach { $0.controller.toggleShortcutCatcher() }
        updateMenuItemStates()
    }

    @objc private func toggleDrawingMode() {
        overlays.forEach { $0.controller.toggleDrawingMode() }
        updateMenuItemStates()
        updateWindowMouseEventHandling()
    }

    @objc private func toggleSpotlight() {
        overlays.forEach { $0.controller.toggleSpotlight() }
        updateMenuItemStates()
    }

    @objc private func toggleZoom() {
        let turnOn = !(overlays.first?.controller.zoomIsOn ?? false)
        if turnOn && !CGPreflightScreenCaptureAccess() {
            requestScreenRecordingPermission()
            return
        }
        overlays.forEach { $0.controller.toggleZoom() }
        updateMenuItemStates()
    }

    // Zoom shows a captured picture of the screen, so it needs Screen Recording. macOS asks only once;
    // after that the setting is opened, as the prompt doesn't appear again
    private func requestScreenRecordingPermission() {
        NSLog("🔐 [Permissions] Screen Recording permission not granted")
        if settings.hasAskedForScreenRecording {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        } else {
            settings.hasAskedForScreenRecording = true
            CGRequestScreenCaptureAccess()
        }
    }

    // Turns everything off if anything is on, otherwise turns everything on.
    // Zoom is only turned off: it needs a permission and isn't meant to be on together with the rest
    @objc private func toggleAllFeatures() {
        let turnOn = !anyFeatureIsOn
        if !turnOn {
            overlays.filter { $0.controller.zoomIsOn }.forEach { $0.controller.toggleZoom() }
        }
        setFeatures(mouse: turnOn, keyboard: turnOn, drawing: turnOn, spotlight: turnOn)
    }

    private var anyFeatureIsOn: Bool {
        guard let controller = overlays.first?.controller else { return false }
        return controller.mouseIsOn || controller.shortcutsCatchIsOn || controller.drawingIsOn || controller.spotlightIsOn
            || controller.zoomIsOn
    }

    private func setFeatures(mouse: Bool, keyboard: Bool, drawing: Bool, spotlight: Bool) {
        for controller in overlays.map({ $0.controller }) {
            if controller.mouseIsOn != mouse { controller.toggleMouseHighlight() }
            if controller.shortcutsCatchIsOn != keyboard { controller.toggleShortcutCatcher() }
            if controller.drawingIsOn != drawing { controller.toggleDrawingMode() }
            if controller.spotlightIsOn != spotlight { controller.toggleSpotlight() }
        }
        updateMenuItemStates()
        updateWindowMouseEventHandling()
    }

    @objc private func clearDrawing() {
        overlays.forEach { $0.controller.clearDrawing() }
    }

    // MARK: - Shortcuts actions
    /// Turns a feature on (true), off (false) or over (nil), the same way as its hotkey
    func setFeature(_ feature: ShortcutsFeature, on: Bool?) {
        guard let controller = overlays.first?.controller else { return }
        switch feature {
        case .mouse:
            if on != controller.mouseIsOn { toggleMouseHighlight() }
        case .keyboard:
            if on != controller.shortcutsCatchIsOn { toggleKeyboardDisplay() }
        case .drawing:
            if on != controller.drawingIsOn { toggleDrawingMode() }
        case .spotlight:
            if on != controller.spotlightIsOn { toggleSpotlight() }
        case .zoom:
            if on != controller.zoomIsOn { toggleZoom() }
        case .all:
            switch on {
            case nil:
                toggleAllFeatures()
            case true:
                setFeatures(mouse: true, keyboard: true, drawing: true, spotlight: true)
            case false:
                if anyFeatureIsOn { toggleAllFeatures() }
            }
        }
    }

    func clearDrawingFromShortcut() {
        clearDrawing()
    }

    @objc private func undoLastStroke() {
        overlays.forEach { $0.controller.undoLastStroke() }
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        // Menu bar (accessory) app: activate so the window comes to front and receives key presses
        activateForWindow()
        settingsWindowController?.showWindow(self)
        settingsWindowController?.window?.makeKeyAndOrderFront(self)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
    }

    // MARK: - Helper Methods
    private func updateMenuItemStates() {
        let controller = overlays.first?.controller

        // Update checkmarks
        mouseItem?.state = controller?.mouseIsOn == true ? .on : .off
        keyboardItem?.state = controller?.shortcutsCatchIsOn == true ? .on : .off
        drawingItem?.state = controller?.drawingIsOn == true ? .on : .off
        spotlightItem?.state = controller?.spotlightIsOn == true ? .on : .off
        zoomItem?.state = controller?.zoomIsOn == true ? .on : .off
        allFeaturesItem?.title = anyFeatureIsOn ? "Turn All Off" : "Turn All On"
    }

    private func updateWindowMouseEventHandling() {
        // ALWAYS keep window transparent to mouse events
        // Drawing uses global event monitors, not window event capture
        overlays.forEach { $0.window.ignoresMouseEvents = true }

        // Ensure windows stay visible and at correct level
        maintainWindowVisibility()
    }

    // MARK: - Window Maintenance
    private func setupWindowMaintenance() {
        NSLog("🔧 [Window] Setting up window maintenance timer...")

        // Run timer every 2 seconds to ensure window stays on top
        windowMaintenanceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.maintainWindowVisibility()
        }

        NSLog("✅ [Window] Maintenance timer started")
    }

    private func maintainWindowVisibility() {
        for window in overlays.map({ $0.window }) {
            maintainVisibility(of: window)
        }
        // Same level as the overlays: keep it in front of them
        colorPalette?.orderFrontRegardless()
    }

    private func maintainVisibility(of window: NSWindow) {
        // Ensure window stays at maximum level
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))

        // ALWAYS keep mouse events passing through
        window.ignoresMouseEvents = true

        // Ensure window stays visible
        if !window.isVisible {
            NSLog("⚠️ [Window] Window became invisible - restoring")
            window.orderFrontRegardless()
        } else {
            // Keep it ordered front even if visible
            window.orderFrontRegardless()
        }

        // Ensure alpha stays at 1.0
        if window.alphaValue < 1.0 {
            NSLog("⚠️ [Window] Window alpha changed to \(window.alphaValue) - resetting to 1.0")
            window.alphaValue = 1.0
        }
    }

    // MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        // Update menu item states to reflect current state
        updateMenuItemStates()
        overlays.forEach { $0.controller.pauseMouseTracking() }
    }

    func menuDidClose(_ menu: NSMenu) {
        overlays.forEach { $0.controller.resumeMouseTracking() }
    }
}
