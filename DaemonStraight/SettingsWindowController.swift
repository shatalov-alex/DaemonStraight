//
//  SettingsWindowController.swift
//  DaemonStraight
//
//  Settings window for configuring app preferences
//

import Cocoa

class SettingsWindowController: NSWindowController, NSWindowDelegate {

    private let settings = SettingsManager.shared

    // Mouse highlighting controls
    private var mouseDefaultColorWell: NSColorWell!
    private var mouseLeftClickColorWell: NSColorWell!
    private var mouseRightClickColorWell: NSColorWell!
    private var mouseDiameterSlider: NSSlider!
    private var mouseDiameterLabel: NSTextField!
    private var mouseWidthSlider: NSSlider!
    private var mouseWidthLabel: NSTextField!

    // Spotlight controls
    private var spotlightDiameterSlider: NSSlider!
    private var spotlightDiameterLabel: NSTextField!
    private var spotlightDimSlider: NSSlider!
    private var spotlightDimLabel: NSTextField!

    // Drawing controls
    private var drawingColorWell: NSColorWell!
    private var drawingWidthSlider: NSSlider!
    private var drawingWidthLabel: NSTextField!

    // Keyboard filter controls
    private var showModifiersCheckbox: NSButton!
    private var showFunctionKeysCheckbox: NSButton!
    private var showAlphanumericCheckbox: NSButton!
    private var showSpecialKeysCheckbox: NSButton!
    private var showModifierClicksCheckbox: NSButton!
    private var shortcutPositionPopup: NSPopUpButton!
    private var keySizeSlider: NSSlider!
    private var keySizeLabel: NSTextField!

    // Hotkey controls
    private var mouseHotkeyRecorder: HotkeyRecorderView!
    private var keyboardHotkeyRecorder: HotkeyRecorderView!
    private var drawingHotkeyRecorder: HotkeyRecorderView!
    private var spotlightHotkeyRecorder: HotkeyRecorderView!
    private var allHotkeyRecorder: HotkeyRecorderView!

    // Launch controls
    private var launchMouseCheckbox: NSButton!
    private var launchKeyboardCheckbox: NSButton!
    private var launchDrawingCheckbox: NSButton!
    private var launchSpotlightCheckbox: NSButton!
    private var checkForUpdatesCheckbox: NSButton!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "DaemonStraight Settings"
        window.center()

        self.init(window: window)
        window.delegate = self
        setupUI()
        loadSettings()
    }

    private func setupUI() {
        guard let window = window else { return }

        let contentView = NSView(frame: window.contentLayoutRect)
        window.contentView = contentView

        let tabView = NSTabView(frame: NSRect(x: 12, y: 60, width: 576, height: 428))
        contentView.addSubview(tabView)
        tabView.addTabViewItem(createTab("Mouse", in: tabView, setup: setupMouseTab))
        tabView.addTabViewItem(createTab("Keyboard", in: tabView, setup: setupKeyboardTab))
        tabView.addTabViewItem(createTab("Drawing", in: tabView, setup: setupDrawingTab))
        tabView.addTabViewItem(createTab("General", in: tabView, setup: setupGeneralTab))

        // MARK: - Buttons
        let resetButton = NSButton(frame: NSRect(x: 30, y: 20, width: 150, height: 32))
        resetButton.title = "Reset to Defaults"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetToDefaults)
        contentView.addSubview(resetButton)

        let closeButton = NSButton(frame: NSRect(x: 470, y: 20, width: 100, height: 32))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.keyEquivalent = "\r"
        contentView.addSubview(closeButton)
    }

    // setup receives the tab's view and the y of its first row (controls are laid out from the top)
    private func createTab(_ title: String, in tabView: NSTabView, setup: (NSView, CGFloat) -> Void) -> NSTabViewItem {
        let item = NSTabViewItem(identifier: title)
        item.label = title
        let view = NSView(frame: NSRect(origin: .zero, size: tabView.contentRect.size))
        setup(view, view.bounds.height - 40)
        item.view = view
        return item
    }

    // MARK: - Mouse Tab
    private func setupMouseTab(_ view: NSView, _ top: CGFloat) {
        var yPosition = top

        view.addSubview(createSectionLabel("Mouse Highlighting", frame: NSRect(x: 20, y: yPosition, width: 520, height: 24)))
        yPosition -= 30

        mouseDefaultColorWell = addColorRow("Default Color:", to: view, y: yPosition)
        yPosition -= 30
        mouseLeftClickColorWell = addColorRow("Left Click Color:", to: view, y: yPosition)
        yPosition -= 30
        mouseRightClickColorWell = addColorRow("Right Click Color:", to: view, y: yPosition)
        yPosition -= 30

        (mouseDiameterSlider, mouseDiameterLabel) = addSliderRow("Diameter:", to: view, y: yPosition, min: 50, max: 300)
        yPosition -= 30
        (mouseWidthSlider, mouseWidthLabel) = addSliderRow("Ring Width:", to: view, y: yPosition, min: 1, max: 10)
        yPosition -= 40

        view.addSubview(createSectionLabel("Spotlight", frame: NSRect(x: 20, y: yPosition, width: 520, height: 24)))
        yPosition -= 30

        (spotlightDiameterSlider, spotlightDiameterLabel) = addSliderRow("Diameter:", to: view, y: yPosition, min: 150, max: 800)
        yPosition -= 30
        (spotlightDimSlider, spotlightDimLabel) = addSliderRow("Dimming:", to: view, y: yPosition, min: 20, max: 90)
    }

    // MARK: - Keyboard Tab
    private func setupKeyboardTab(_ view: NSView, _ top: CGFloat) {
        var yPosition = top

        view.addSubview(createSectionLabel("Keyboard Display Filter", frame: NSRect(x: 20, y: yPosition, width: 520, height: 24)))
        yPosition -= 30

        let showKeysLabel = createLabel("Show keys:", frame: NSRect(x: 30, y: yPosition, width: 300, height: 20))
        showKeysLabel.alignment = .left
        view.addSubview(showKeysLabel)
        yPosition -= 25

        showModifiersCheckbox = createCheckbox("Modifier keys (⌘⌃⌥⇧)", frame: NSRect(x: 40, y: yPosition, width: 400, height: 20))
        view.addSubview(showModifiersCheckbox)
        yPosition -= 25

        showFunctionKeysCheckbox = createCheckbox("Function keys (F1-F12)", frame: NSRect(x: 40, y: yPosition, width: 400, height: 20))
        view.addSubview(showFunctionKeysCheckbox)
        yPosition -= 25

        showAlphanumericCheckbox = createCheckbox("Plain typing (A-Z, 0-9 without ⌘⌃⌥)", frame: NSRect(x: 40, y: yPosition, width: 400, height: 20))
        view.addSubview(showAlphanumericCheckbox)
        yPosition -= 25

        showSpecialKeysCheckbox = createCheckbox("Special keys (Esc, Tab, Return, Delete, arrows)", frame: NSRect(x: 40, y: yPosition, width: 400, height: 20))
        view.addSubview(showSpecialKeysCheckbox)
        yPosition -= 25

        showModifierClicksCheckbox = createCheckbox("Mouse clicks with modifiers (⌘ Click, ⌥ Right Click)", frame: NSRect(x: 40, y: yPosition, width: 400, height: 20))
        view.addSubview(showModifierClicksCheckbox)
        yPosition -= 40

        view.addSubview(createSectionLabel("Appearance", frame: NSRect(x: 20, y: yPosition, width: 520, height: 24)))
        yPosition -= 32

        view.addSubview(createLabel("Position:", frame: NSRect(x: 30, y: yPosition + 3, width: 120, height: 20)))
        shortcutPositionPopup = NSPopUpButton(frame: NSRect(x: 158, y: yPosition, width: 160, height: 26), pullsDown: false)
        shortcutPositionPopup.addItems(withTitles: SettingsManager.ShortcutPosition.allCases.map { $0.title })
        shortcutPositionPopup.target = self
        shortcutPositionPopup.action = #selector(shortcutPositionChanged)
        view.addSubview(shortcutPositionPopup)
        yPosition -= 32

        (keySizeSlider, keySizeLabel) = addSliderRow("Key Size:", to: view, y: yPosition, min: 40, max: 110)
    }

    // MARK: - Drawing Tab
    private func setupDrawingTab(_ view: NSView, _ top: CGFloat) {
        var yPosition = top

        view.addSubview(createSectionLabel("Drawing Mode", frame: NSRect(x: 20, y: yPosition, width: 520, height: 24)))
        yPosition -= 30

        drawingColorWell = addColorRow("Line Color:", to: view, y: yPosition)
        yPosition -= 30

        (drawingWidthSlider, drawingWidthLabel) = addSliderRow("Line Width:", to: view, y: yPosition, min: 1, max: 15)
    }

    // MARK: - General Tab
    private func setupGeneralTab(_ view: NSView, _ top: CGFloat) {
        var yPosition = top

        view.addSubview(createSectionLabel("Hotkeys", frame: NSRect(x: 20, y: yPosition, width: 520, height: 24)))
        yPosition -= 30

        mouseHotkeyRecorder = addHotkeyRow("Toggle Mouse:", to: view, y: yPosition)
        yPosition -= 35
        keyboardHotkeyRecorder = addHotkeyRow("Toggle Keyboard:", to: view, y: yPosition)
        yPosition -= 35
        drawingHotkeyRecorder = addHotkeyRow("Toggle Drawing:", to: view, y: yPosition)
        yPosition -= 35
        spotlightHotkeyRecorder = addHotkeyRow("Toggle Spotlight:", to: view, y: yPosition)
        yPosition -= 35
        allHotkeyRecorder = addHotkeyRow("Toggle All:", to: view, y: yPosition)
        yPosition -= 45

        view.addSubview(createSectionLabel("At Launch", frame: NSRect(x: 20, y: yPosition, width: 520, height: 24)))
        yPosition -= 30

        let launchLabel = createLabel("Turn on when the app starts:", frame: NSRect(x: 30, y: yPosition, width: 300, height: 20))
        launchLabel.alignment = .left
        view.addSubview(launchLabel)
        yPosition -= 25

        launchMouseCheckbox = createCheckbox("Mouse Highlighting", frame: NSRect(x: 40, y: yPosition, width: 220, height: 20))
        view.addSubview(launchMouseCheckbox)
        launchKeyboardCheckbox = createCheckbox("Keyboard Display", frame: NSRect(x: 280, y: yPosition, width: 220, height: 20))
        view.addSubview(launchKeyboardCheckbox)
        yPosition -= 25

        launchDrawingCheckbox = createCheckbox("Drawing Mode", frame: NSRect(x: 40, y: yPosition, width: 220, height: 20))
        view.addSubview(launchDrawingCheckbox)
        launchSpotlightCheckbox = createCheckbox("Spotlight", frame: NSRect(x: 280, y: yPosition, width: 220, height: 20))
        view.addSubview(launchSpotlightCheckbox)
        yPosition -= 30

        checkForUpdatesCheckbox = createCheckbox("Check for updates when the app starts", frame: NSRect(x: 30, y: yPosition, width: 400, height: 20))
        view.addSubview(checkForUpdatesCheckbox)
    }

    // MARK: - Control Helpers
    private func addColorRow(_ title: String, to view: NSView, y: CGFloat) -> NSColorWell {
        view.addSubview(createLabel(title, frame: NSRect(x: 30, y: y + 3, width: 120, height: 20)))
        let well = NSColorWell(frame: NSRect(x: 160, y: y, width: 80, height: 26))
        well.target = self
        well.action = #selector(colorChanged)
        view.addSubview(well)
        return well
    }

    private func addSliderRow(_ title: String, to view: NSView, y: CGFloat, min: Double, max: Double) -> (NSSlider, NSTextField) {
        view.addSubview(createLabel(title, frame: NSRect(x: 30, y: y, width: 120, height: 20)))
        let slider = NSSlider(frame: NSRect(x: 160, y: y, width: 300, height: 20))
        slider.minValue = min
        slider.maxValue = max
        slider.target = self
        slider.action = #selector(sliderChanged)
        view.addSubview(slider)
        let valueLabel = createLabel("", frame: NSRect(x: 470, y: y, width: 60, height: 20))
        valueLabel.alignment = .left
        view.addSubview(valueLabel)
        return (slider, valueLabel)
    }

    private func addHotkeyRow(_ title: String, to view: NSView, y: CGFloat) -> HotkeyRecorderView {
        view.addSubview(createLabel(title, frame: NSRect(x: 30, y: y, width: 120, height: 20)))
        let recorder = HotkeyRecorderView(frame: NSRect(x: 160, y: y - 4, width: 200, height: 28))
        recorder.onChange = { [weak self] in self?.saveHotkeys() }
        view.addSubview(recorder)
        return recorder
    }

    private func createSectionLabel(_ text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(frame: frame)
        label.stringValue = text
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.font = NSFont.boldSystemFont(ofSize: 14)
        return label
    }

    private func createLabel(_ text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(frame: frame)
        label.stringValue = text
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.alignment = .right
        return label
    }

    private func createCheckbox(_ title: String, frame: NSRect) -> NSButton {
        let checkbox = NSButton(frame: frame)
        checkbox.setButtonType(.switch)
        checkbox.title = title
        checkbox.target = self
        checkbox.action = #selector(checkboxChanged)
        return checkbox
    }

    private func loadSettings() {
        // Mouse highlighting
        mouseDefaultColorWell.color = settings.mouseDefaultColor
        mouseLeftClickColorWell.color = settings.mouseLeftClickColor
        mouseRightClickColorWell.color = settings.mouseRightClickColor
        mouseDiameterSlider.doubleValue = Double(settings.mouseDiameter)
        mouseWidthSlider.doubleValue = Double(settings.mouseWidth)

        // Spotlight
        spotlightDiameterSlider.doubleValue = Double(settings.spotlightDiameter)
        spotlightDimSlider.doubleValue = Double(settings.spotlightDimOpacity * 100)

        // Drawing
        drawingColorWell.color = settings.drawingColor
        drawingWidthSlider.doubleValue = Double(settings.drawingWidth)

        // Keyboard filter
        showModifiersCheckbox.state = settings.showModifierKeys ? .on : .off
        showFunctionKeysCheckbox.state = settings.showFunctionKeys ? .on : .off
        showAlphanumericCheckbox.state = settings.showAlphanumericKeys ? .on : .off
        showSpecialKeysCheckbox.state = settings.showSpecialKeys ? .on : .off
        showModifierClicksCheckbox.state = settings.showModifierClicks ? .on : .off
        shortcutPositionPopup.selectItem(at: settings.shortcutPosition.rawValue)
        keySizeSlider.doubleValue = Double(settings.shortcutKeySize)

        // Hotkeys
        mouseHotkeyRecorder.hotkey = settings.mouseToggleHotkey
        keyboardHotkeyRecorder.hotkey = settings.keyboardToggleHotkey
        drawingHotkeyRecorder.hotkey = settings.drawingToggleHotkey
        spotlightHotkeyRecorder.hotkey = settings.spotlightToggleHotkey
        allHotkeyRecorder.hotkey = settings.allToggleHotkey

        // Launch
        launchMouseCheckbox.state = settings.launchWithMouse ? .on : .off
        launchKeyboardCheckbox.state = settings.launchWithKeyboard ? .on : .off
        launchDrawingCheckbox.state = settings.launchWithDrawing ? .on : .off
        launchSpotlightCheckbox.state = settings.launchWithSpotlight ? .on : .off
        checkForUpdatesCheckbox.state = settings.checkForUpdatesAtLaunch ? .on : .off

        updateSliderLabels()
    }

    private func updateSliderLabels() {
        mouseDiameterLabel.stringValue = "\(Int(settings.mouseDiameter))"
        mouseWidthLabel.stringValue = "\(Int(settings.mouseWidth))"
        spotlightDiameterLabel.stringValue = "\(Int(settings.spotlightDiameter))"
        spotlightDimLabel.stringValue = "\(Int((settings.spotlightDimOpacity * 100).rounded()))%"
        drawingWidthLabel.stringValue = "\(Int(settings.drawingWidth))"
        keySizeLabel.stringValue = "\(Int(settings.shortcutKeySize))"
    }

    @objc private func colorChanged() {
        settings.mouseDefaultColor = mouseDefaultColorWell.color
        settings.mouseLeftClickColor = mouseLeftClickColorWell.color
        settings.mouseRightClickColor = mouseRightClickColorWell.color
        settings.drawingColor = drawingColorWell.color
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }

    @objc private func sliderChanged() {
        // Whole numbers only
        settings.mouseDiameter = CGFloat(mouseDiameterSlider.doubleValue.rounded())
        settings.mouseWidth = CGFloat(mouseWidthSlider.doubleValue.rounded())
        settings.spotlightDiameter = CGFloat(spotlightDiameterSlider.doubleValue.rounded())
        settings.spotlightDimOpacity = CGFloat(spotlightDimSlider.doubleValue.rounded()) / 100
        settings.drawingWidth = CGFloat(drawingWidthSlider.doubleValue.rounded())
        settings.shortcutKeySize = CGFloat(keySizeSlider.doubleValue.rounded())
        updateSliderLabels()

        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }

    @objc private func checkboxChanged() {
        settings.showModifierKeys = showModifiersCheckbox.state == .on
        settings.showFunctionKeys = showFunctionKeysCheckbox.state == .on
        settings.showAlphanumericKeys = showAlphanumericCheckbox.state == .on
        settings.showSpecialKeys = showSpecialKeysCheckbox.state == .on
        settings.showModifierClicks = showModifierClicksCheckbox.state == .on
        settings.launchWithMouse = launchMouseCheckbox.state == .on
        settings.launchWithKeyboard = launchKeyboardCheckbox.state == .on
        settings.launchWithDrawing = launchDrawingCheckbox.state == .on
        settings.launchWithSpotlight = launchSpotlightCheckbox.state == .on
        settings.checkForUpdatesAtLaunch = checkForUpdatesCheckbox.state == .on
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }

    @objc private func shortcutPositionChanged() {
        settings.shortcutPosition = SettingsManager.ShortcutPosition(rawValue: shortcutPositionPopup.indexOfSelectedItem) ?? .bottomLeft
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }

    @objc private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = "Reset to Defaults"
        alert.informativeText = "Are you sure you want to reset all settings to their default values?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            settings.resetToDefaults()
            loadSettings()
            NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        }
    }

    private var hotkeyRecorders: [HotkeyRecorderView] {
        [mouseHotkeyRecorder, keyboardHotkeyRecorder, drawingHotkeyRecorder, spotlightHotkeyRecorder, allHotkeyRecorder]
    }

    private func saveHotkeys() {
        settings.mouseToggleHotkey = mouseHotkeyRecorder.hotkey
        settings.keyboardToggleHotkey = keyboardHotkeyRecorder.hotkey
        settings.drawingToggleHotkey = drawingHotkeyRecorder.hotkey
        settings.spotlightToggleHotkey = spotlightHotkeyRecorder.hotkey
        settings.allToggleHotkey = allHotkeyRecorder.hotkey
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }

    @objc private func closeWindow() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        hotkeyRecorders.forEach { $0.cancelRecording() }
        saveHotkeys()
    }
}

// MARK: - Hotkey Recorder View
class HotkeyRecorderView: NSView {
    var hotkey: SettingsManager.Hotkey {
        didSet {
            updateDisplay()
        }
    }

    // Called after a new hotkey has been recorded
    var onChange: (() -> Void)?

    // True while any recorder waits for keys - global hotkeys are ignored meanwhile
    static var isRecordingAny = false

    private var label: NSTextField!
    private var isRecording = false
    private var localMonitor: Any?

    override init(frame frameRect: NSRect) {
        // Default hotkey
        self.hotkey = SettingsManager.Hotkey(keyCode: 46, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue)
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        self.hotkey = SettingsManager.Hotkey(keyCode: 46, modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue)
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor

        label = NSTextField(labelWithString: "")
        label.alignment = .center
        let labelHeight = label.intrinsicContentSize.height
        label.frame = NSRect(x: 8, y: (bounds.height - labelHeight) / 2, width: bounds.width - 16, height: labelHeight)
        label.autoresizingMask = [.width, .minYMargin, .maxYMargin]
        addSubview(label)

        updateDisplay()

        // Make it clickable
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(startRecording))
        addGestureRecognizer(clickGesture)
    }

    private func updateDisplay() {
        label.stringValue = isRecording ? "Press keys... (Esc to cancel)" : hotkey.description
        label.textColor = isRecording ? .alternateSelectedControlTextColor : .labelColor

        // Dynamic colors must be resolved in the view's appearance, otherwise cgColor can come out black
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = (isRecording ? NSColor.selectedContentBackgroundColor : NSColor.controlBackgroundColor).cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateDisplay()
    }

    @objc private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        HotkeyRecorderView.isRecordingAny = true
        updateDisplay()

        // Add local event monitor
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Esc cancels recording
            if event.keyCode == 53 {
                self.stopRecording()
                return nil
            }

            // Require ⌃, ⌥ or ⌘ - otherwise plain typing would toggle modes
            let modifiers = event.modifierFlags.intersection([.control, .option, .command, .shift])
            guard !modifiers.intersection([.control, .option, .command]).isEmpty else {
                NSSound.beep()
                return nil
            }

            self.hotkey = SettingsManager.Hotkey(keyCode: event.keyCode, modifiers: modifiers.rawValue)
            self.stopRecording()
            self.onChange?()
            return nil
        }
    }

    func cancelRecording() {
        if isRecording {
            stopRecording()
        }
    }

    private func stopRecording() {
        isRecording = false
        HotkeyRecorderView.isRecordingAny = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        updateDisplay()
    }

    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            startRecording()
        }
    }
}
