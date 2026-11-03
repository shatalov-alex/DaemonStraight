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
    private var overlayWindow: NSWindow!
    private var overlayViewController: ViewController!
    private var settingsWindowController: SettingsWindowController?
    private let settings = SettingsManager.shared

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

        // Setup overlay window
        setupOverlayWindow()
        NSLog("✅ [AppDelegate] Overlay window setup complete")

        // Setup global keyboard shortcuts
        setupGlobalKeyboardShortcuts()
        NSLog("✅ [AppDelegate] Global keyboard shortcuts setup complete")

        // Setup window maintenance timer
        setupWindowMaintenance()

        NSLog("🎉 [AppDelegate] Application ready! All features are OFF by default.")
        NSLog("⌨️  [AppDelegate] Keyboard shortcuts:")
        NSLog("    ⌃⌥⌘M - Toggle mouse highlighting")
        NSLog("    ⌃⌥⌘K - Toggle keyboard display")
        NSLog("    ⌃⌥⌘D - Toggle drawing mode")
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

        // Mouse Highlighting toggle
        let mouseItem = NSMenuItem(title: "Mouse Highlighting", action: #selector(toggleMouseHighlight), keyEquivalent: "")
        mouseItem.target = self
        mouseItem.state = overlayViewController?.mouseIsOn == true ? .on : .off
        menu.addItem(mouseItem)

        // Keyboard Display toggle
        let keyboardItem = NSMenuItem(title: "Keyboard Display", action: #selector(toggleKeyboardDisplay), keyEquivalent: "")
        keyboardItem.target = self
        keyboardItem.state = overlayViewController?.shortcutsCatchIsOn == true ? .on : .off
        menu.addItem(keyboardItem)

        // Drawing Mode toggle
        let drawingItem = NSMenuItem(title: "Drawing Mode", action: #selector(toggleDrawingMode), keyEquivalent: "")
        drawingItem.target = self
        drawingItem.state = overlayViewController?.drawingIsOn == true ? .on : .off
        menu.addItem(drawingItem)

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

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")

        statusItem.menu = menu
    }

    // MARK: - Overlay Window Setup
    private func setupOverlayWindow() {
        // Get all screens
        let screens = NSScreen.screens

        // Use main screen for simplicity, but could support multiple displays
        guard let screen = screens.first else { return }

        // Create fullscreen window covering entire screen including menu bar
        let frame = screen.frame

        // Create custom overlay window that never becomes key
        overlayWindow = TransparentOverlayWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false

        // Use the highest possible window level for overlays
        overlayWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))

        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        overlayWindow.ignoresMouseEvents = true  // Start with pass-through enabled
        overlayWindow.acceptsMouseMovedEvents = true
        overlayWindow.alphaValue = 1.0  // Keep fully visible

        NSLog("🪟 [Window] Created overlay window at level: \(overlayWindow.level.rawValue)")
        NSLog("🪟 [Window] Frame: \(NSStringFromRect(frame))")
        NSLog("🪟 [Window] Screen frame: \(NSStringFromRect(screen.frame))")

        // Create view controller with screen size
        overlayViewController = ViewController(screenSize: frame.size)
        overlayWindow.contentViewController = overlayViewController

        NSLog("🪟 [Window] ViewController view frame: \(NSStringFromRect(overlayViewController.view.frame))")
        NSLog("🪟 [Window] ViewController view bounds: \(NSStringFromRect(overlayViewController.view.bounds))")

        // Ensure autoresizing works
        overlayViewController.view.autoresizingMask = [.width, .height]

        // CRITICAL: Ensure contentView covers entire window
        if let contentView = overlayWindow.contentView {
            contentView.autoresizingMask = [.width, .height]
            NSLog("🪟 [Window] ContentView frame: \(NSStringFromRect(contentView.frame))")
            NSLog("🪟 [Window] ContentView bounds: \(NSStringFromRect(contentView.bounds))")
        }

        // Show window - use orderFrontRegardless to keep it visible
        overlayWindow.orderFrontRegardless()

        NSLog("🪟 [Window] Window ordered front (never becomes key)")
        NSLog("🪟 [Window] Window is visible: \(overlayWindow.isVisible)")
        NSLog("🪟 [Window] Window alpha: \(overlayWindow.alphaValue)")
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

        if keyCode == mouseHotkey.keyCode && modifiers.rawValue == mouseHotkey.modifiers {
            toggleMouseHighlight()
        } else if keyCode == keyboardHotkey.keyCode && modifiers.rawValue == keyboardHotkey.modifiers {
            toggleKeyboardDisplay()
        } else if keyCode == drawingHotkey.keyCode && modifiers.rawValue == drawingHotkey.modifiers {
            toggleDrawingMode()
        }
    }

    // MARK: - Menu Actions
    @objc private func toggleMouseHighlight() {
        overlayViewController?.toggleMouseHighlight()
        updateMenuItemStates()
        updateWindowMouseEventHandling()
    }

    @objc private func toggleKeyboardDisplay() {
        overlayViewController?.toggleShortcutCatcher()
        updateMenuItemStates()
    }

    @objc private func toggleDrawingMode() {
        overlayViewController?.toggleDrawingMode()
        updateMenuItemStates()
        updateWindowMouseEventHandling()
    }

    @objc private func clearDrawing() {
        overlayViewController?.clearDrawing()
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
        guard let menu = statusItem.menu else { return }

        // Update checkmarks
        if let mouseItem = menu.item(withTitle: "Mouse Highlighting") {
            mouseItem.state = overlayViewController?.mouseIsOn == true ? .on : .off
        }

        if let keyboardItem = menu.item(withTitle: "Keyboard Display") {
            keyboardItem.state = overlayViewController?.shortcutsCatchIsOn == true ? .on : .off
        }

        if let drawingItem = menu.item(withTitle: "Drawing Mode") {
            drawingItem.state = overlayViewController?.drawingIsOn == true ? .on : .off
        }
    }

    private func updateWindowMouseEventHandling() {
        // ALWAYS keep window transparent to mouse events
        // Drawing uses global event monitors, not window event capture
        overlayWindow.ignoresMouseEvents = true

        // Ensure window stays visible and at correct level
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
        guard let window = overlayWindow else { return }

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
        overlayViewController?.pauseMouseTracking()
    }

    func menuDidClose(_ menu: NSMenu) {
        overlayViewController?.resumeMouseTracking()
    }
}
