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
    private var allFeaturesItem: NSMenuItem!
    private var updatesItem: NSMenuItem!
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

        // Request accessibility permissions
        requestAccessibilityPermissions()

        // Setup menu bar
        setupMenuBar()
        NSLog("✅ [AppDelegate] Menu bar setup complete")

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
    private func requestAccessibilityPermissions() {
        NSLog("🔐 [Permissions] Checking accessibility permissions...")

        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if accessEnabled {
            NSLog("✅ [Permissions] Accessibility permissions GRANTED")
        } else {
            NSLog("⚠️  [Permissions] Accessibility permissions NOT granted")
            NSLog("📋 [Permissions] Please grant accessibility access in System Settings")

            let alert = NSAlert()
            alert.messageText = "Accessibility Access Required"
            alert.informativeText = "DaemonStraight needs accessibility permissions to monitor keyboard and mouse events for presentation assistance.\n\nPlease grant access in System Settings > Privacy & Security > Accessibility.\n\nWhen running from Xcode, Xcode may need to be in that list as well."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSLog("🔓 [Permissions] Opening System Settings...")
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
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

        NSApp.activate(ignoringOtherApps: true)
        settings.checkForUpdatesAtLaunch = alert.runModal() == .alertFirstButtonReturn
    }

    // A quiet hint in the menu bar: an update window must not appear during a presentation
    private func showAvailableUpdate(_ version: String?) {
        let symbol = version == nil ? "display" : "arrow.down.circle"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "DaemonStraight")
        statusItem.button?.image?.isTemplate = true
        updatesItem.title = version.map { "Update to \($0)..." } ?? "Check for Updates..."
    }

    @objc private func checkForUpdates() {
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

        menu.addItem(NSMenuItem.separator())

        allFeaturesItem = NSMenuItem(title: "Turn All On", action: #selector(toggleAllFeatures), keyEquivalent: "")
        allFeaturesItem.target = self
        menu.addItem(allFeaturesItem)

        menu.addItem(NSMenuItem.separator())

        // Clear Drawing
        let clearItem = NSMenuItem(title: "Clear Drawing", action: #selector(clearDrawing), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

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

        for overlay in overlays {
            overlay.window.orderOut(nil)
            overlay.window.contentViewController = nil
            overlay.window.close()
        }
        overlays.removeAll()
        setupOverlayWindows()

        setFeatures(mouse: mouseOn, keyboard: keyboardOn, drawing: drawingOn, spotlight: spotlightOn)
    }

    // MARK: - Global Keyboard Shortcuts
    private func setupGlobalKeyboardShortcuts() {
        NSLog("⌨️  [Shortcuts] Setting up global keyboard shortcut monitoring...")

        // Local monitor - captures events for this app
        localHotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkeyEvent(event)
            return event
        }

        // Global monitor - captures ALL system events (requires accessibility permissions)
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkeyEvent(event)
        }

        NSLog("✅ [Shortcuts] Global keyboard shortcut monitoring active")
        NSLog("🎯 [Shortcuts] Listening for system-wide keyboard events...")
    }

    private func handleHotkeyEvent(_ event: NSEvent) {
        // Don't toggle modes while a new hotkey is being recorded in Settings
        guard !HotkeyRecorderView.isRecordingAny else { return }

        let modifiers = event.modifierFlags.intersection([.control, .option, .command, .shift])
        let keyCode = event.keyCode

        // Check against custom hotkeys
        let mouseHotkey = settings.mouseToggleHotkey
        let keyboardHotkey = settings.keyboardToggleHotkey
        let drawingHotkey = settings.drawingToggleHotkey
        let spotlightHotkey = settings.spotlightToggleHotkey
        let allHotkey = settings.allToggleHotkey

        if keyCode == mouseHotkey.keyCode && modifiers.rawValue == mouseHotkey.modifiers {
            toggleMouseHighlight()
        } else if keyCode == keyboardHotkey.keyCode && modifiers.rawValue == keyboardHotkey.modifiers {
            toggleKeyboardDisplay()
        } else if keyCode == drawingHotkey.keyCode && modifiers.rawValue == drawingHotkey.modifiers {
            toggleDrawingMode()
        } else if keyCode == spotlightHotkey.keyCode && modifiers.rawValue == spotlightHotkey.modifiers {
            toggleSpotlight()
        } else if keyCode == allHotkey.keyCode && modifiers.rawValue == allHotkey.modifiers {
            toggleAllFeatures()
        }
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

    // Turns everything off if anything is on, otherwise turns everything on
    @objc private func toggleAllFeatures() {
        let turnOn = !anyFeatureIsOn
        setFeatures(mouse: turnOn, keyboard: turnOn, drawing: turnOn, spotlight: turnOn)
    }

    private var anyFeatureIsOn: Bool {
        guard let controller = overlays.first?.controller else { return false }
        return controller.mouseIsOn || controller.shortcutsCatchIsOn || controller.drawingIsOn || controller.spotlightIsOn
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

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        // Menu bar (accessory) app: activate so the window comes to front and receives key presses
        NSApp.activate(ignoringOtherApps: true)
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
