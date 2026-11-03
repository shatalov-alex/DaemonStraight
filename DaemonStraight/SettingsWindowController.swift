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

    // Drawing controls
    private var drawingColorWell: NSColorWell!
    private var drawingWidthSlider: NSSlider!
    private var drawingWidthLabel: NSTextField!

    // Keyboard filter controls
    private var showModifiersCheckbox: NSButton!
    private var showFunctionKeysCheckbox: NSButton!
    private var showAlphanumericCheckbox: NSButton!
    private var showSpecialKeysCheckbox: NSButton!

    // Hotkey controls
    private var mouseHotkeyRecorder: HotkeyRecorderView!
    private var keyboardHotkeyRecorder: HotkeyRecorderView!
    private var drawingHotkeyRecorder: HotkeyRecorderView!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 690),
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

        var yPosition: CGFloat = 650

        // MARK: - Mouse Highlighting Section
        let mouseLabel = createSectionLabel("Mouse Highlighting", frame: NSRect(x: 20, y: yPosition, width: 560, height: 24))
        contentView.addSubview(mouseLabel)
        yPosition -= 30

        // Default color
        contentView.addSubview(createLabel("Default Color:", frame: NSRect(x: 30, y: yPosition + 3, width: 120, height: 20)))
        mouseDefaultColorWell = NSColorWell(frame: NSRect(x: 160, y: yPosition, width: 80, height: 26))
        mouseDefaultColorWell.target = self
        mouseDefaultColorWell.action = #selector(colorChanged)
        contentView.addSubview(mouseDefaultColorWell)
        yPosition -= 30

        // Left click color
        contentView.addSubview(createLabel("Left Click Color:", frame: NSRect(x: 30, y: yPosition + 3, width: 120, height: 20)))
        mouseLeftClickColorWell = NSColorWell(frame: NSRect(x: 160, y: yPosition, width: 80, height: 26))
        mouseLeftClickColorWell.target = self
        mouseLeftClickColorWell.action = #selector(colorChanged)
        contentView.addSubview(mouseLeftClickColorWell)
        yPosition -= 30

        // Right click color
        contentView.addSubview(createLabel("Right Click Color:", frame: NSRect(x: 30, y: yPosition + 3, width: 120, height: 20)))
        mouseRightClickColorWell = NSColorWell(frame: NSRect(x: 160, y: yPosition, width: 80, height: 26))
        mouseRightClickColorWell.target = self
        mouseRightClickColorWell.action = #selector(colorChanged)
        contentView.addSubview(mouseRightClickColorWell)
        yPosition -= 30

        // Diameter
        contentView.addSubview(createLabel("Diameter:", frame: NSRect(x: 30, y: yPosition, width: 120, height: 20)))
        mouseDiameterSlider = NSSlider(frame: NSRect(x: 160, y: yPosition, width: 300, height: 20))
        mouseDiameterSlider.minValue = 50
        mouseDiameterSlider.maxValue = 300
        mouseDiameterSlider.target = self
        mouseDiameterSlider.action = #selector(sliderChanged)
        contentView.addSubview(mouseDiameterSlider)
        mouseDiameterLabel = createLabel("150", frame: NSRect(x: 470, y: yPosition, width: 50, height: 20))
        mouseDiameterLabel.alignment = .left
        contentView.addSubview(mouseDiameterLabel)
        yPosition -= 30

        // Width
        contentView.addSubview(createLabel("Ring Width:", frame: NSRect(x: 30, y: yPosition, width: 120, height: 20)))
        mouseWidthSlider = NSSlider(frame: NSRect(x: 160, y: yPosition, width: 300, height: 20))
        mouseWidthSlider.minValue = 1
        mouseWidthSlider.maxValue = 10
        mouseWidthSlider.target = self
        mouseWidthSlider.action = #selector(sliderChanged)
        contentView.addSubview(mouseWidthSlider)
        mouseWidthLabel = createLabel("4", frame: NSRect(x: 470, y: yPosition, width: 50, height: 20))
        mouseWidthLabel.alignment = .left
        contentView.addSubview(mouseWidthLabel)
        yPosition -= 40

        // MARK: - Drawing Section
        let drawingLabel = createSectionLabel("Drawing Mode", frame: NSRect(x: 20, y: yPosition, width: 560, height: 24))
        contentView.addSubview(drawingLabel)
        yPosition -= 30

        // Drawing color
        contentView.addSubview(createLabel("Line Color:", frame: NSRect(x: 30, y: yPosition + 3, width: 120, height: 20)))
        drawingColorWell = NSColorWell(frame: NSRect(x: 160, y: yPosition, width: 80, height: 26))
        drawingColorWell.target = self
        drawingColorWell.action = #selector(colorChanged)
        contentView.addSubview(drawingColorWell)
        yPosition -= 30

        // Drawing width
        contentView.addSubview(createLabel("Line Width:", frame: NSRect(x: 30, y: yPosition, width: 120, height: 20)))
        drawingWidthSlider = NSSlider(frame: NSRect(x: 160, y: yPosition, width: 300, height: 20))
        drawingWidthSlider.minValue = 1
        drawingWidthSlider.maxValue = 15
        drawingWidthSlider.target = self
        drawingWidthSlider.action = #selector(sliderChanged)
        contentView.addSubview(drawingWidthSlider)
        drawingWidthLabel = createLabel("5", frame: NSRect(x: 470, y: yPosition, width: 50, height: 20))
        drawingWidthLabel.alignment = .left
        contentView.addSubview(drawingWidthLabel)
        yPosition -= 40

        // MARK: - Keyboard Display Filter
        let keyboardLabel = createSectionLabel("Keyboard Display Filter", frame: NSRect(x: 20, y: yPosition, width: 560, height: 24))
        contentView.addSubview(keyboardLabel)
        yPosition -= 30

        let showKeysLabel = createLabel("Show keys:", frame: NSRect(x: 30, y: yPosition, width: 300, height: 20))
        showKeysLabel.alignment = .left
        contentView.addSubview(showKeysLabel)
        yPosition -= 25

        showModifiersCheckbox = createCheckbox("Modifier keys (⌘⌃⌥⇧)", frame: NSRect(x: 40, y: yPosition, width: 350, height: 20))
        contentView.addSubview(showModifiersCheckbox)
        yPosition -= 25

        showFunctionKeysCheckbox = createCheckbox("Function keys (F1-F12)", frame: NSRect(x: 40, y: yPosition, width: 350, height: 20))
        contentView.addSubview(showFunctionKeysCheckbox)
        yPosition -= 25

        showAlphanumericCheckbox = createCheckbox("Plain typing (A-Z, 0-9 without ⌘⌃⌥)", frame: NSRect(x: 40, y: yPosition, width: 350, height: 20))
        contentView.addSubview(showAlphanumericCheckbox)
        yPosition -= 25

        showSpecialKeysCheckbox = createCheckbox("Special keys (Esc, Tab, Return, Delete, arrows)", frame: NSRect(x: 40, y: yPosition, width: 350, height: 20))
        contentView.addSubview(showSpecialKeysCheckbox)
        yPosition -= 40

        // MARK: - Hotkeys Section
        let hotkeysLabel = createSectionLabel("Hotkeys", frame: NSRect(x: 20, y: yPosition, width: 560, height: 24))
        contentView.addSubview(hotkeysLabel)
        yPosition -= 30

        // Mouse toggle hotkey
        contentView.addSubview(createLabel("Toggle Mouse:", frame: NSRect(x: 30, y: yPosition, width: 120, height: 20)))
        mouseHotkeyRecorder = HotkeyRecorderView(frame: NSRect(x: 160, y: yPosition - 4, width: 200, height: 28))
        mouseHotkeyRecorder.onChange = { [weak self] in self?.saveHotkeys() }
        contentView.addSubview(mouseHotkeyRecorder)
        yPosition -= 35

        // Keyboard toggle hotkey
        contentView.addSubview(createLabel("Toggle Keyboard:", frame: NSRect(x: 30, y: yPosition, width: 120, height: 20)))
        keyboardHotkeyRecorder = HotkeyRecorderView(frame: NSRect(x: 160, y: yPosition - 4, width: 200, height: 28))
        keyboardHotkeyRecorder.onChange = { [weak self] in self?.saveHotkeys() }
        contentView.addSubview(keyboardHotkeyRecorder)
        yPosition -= 35

        // Drawing toggle hotkey
        contentView.addSubview(createLabel("Toggle Drawing:", frame: NSRect(x: 30, y: yPosition, width: 120, height: 20)))
        drawingHotkeyRecorder = HotkeyRecorderView(frame: NSRect(x: 160, y: yPosition - 4, width: 200, height: 28))
        drawingHotkeyRecorder.onChange = { [weak self] in self?.saveHotkeys() }
        contentView.addSubview(drawingHotkeyRecorder)
        yPosition -= 50

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
        mouseDiameterLabel.stringValue = "\(Int(settings.mouseDiameter))"
        mouseWidthSlider.doubleValue = Double(settings.mouseWidth)
        mouseWidthLabel.stringValue = "\(Int(settings.mouseWidth))"

        // Drawing
        drawingColorWell.color = settings.drawingColor
        drawingWidthSlider.doubleValue = Double(settings.drawingWidth)
        drawingWidthLabel.stringValue = "\(Int(settings.drawingWidth))"

        // Keyboard filter
        showModifiersCheckbox.state = settings.showModifierKeys ? .on : .off
        showFunctionKeysCheckbox.state = settings.showFunctionKeys ? .on : .off
        showAlphanumericCheckbox.state = settings.showAlphanumericKeys ? .on : .off
        showSpecialKeysCheckbox.state = settings.showSpecialKeys ? .on : .off

        // Hotkeys
        mouseHotkeyRecorder.hotkey = settings.mouseToggleHotkey
        keyboardHotkeyRecorder.hotkey = settings.keyboardToggleHotkey
        drawingHotkeyRecorder.hotkey = settings.drawingToggleHotkey
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
        let diameter = mouseDiameterSlider.doubleValue.rounded()
        settings.mouseDiameter = CGFloat(diameter)
        mouseDiameterLabel.stringValue = "\(Int(diameter))"

        let mouseWidth = mouseWidthSlider.doubleValue.rounded()
        settings.mouseWidth = CGFloat(mouseWidth)
        mouseWidthLabel.stringValue = "\(Int(mouseWidth))"

        let drawingWidth = drawingWidthSlider.doubleValue.rounded()
        settings.drawingWidth = CGFloat(drawingWidth)
        drawingWidthLabel.stringValue = "\(Int(drawingWidth))"

        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }

    @objc private func checkboxChanged() {
        settings.showModifierKeys = showModifiersCheckbox.state == .on
        settings.showFunctionKeys = showFunctionKeysCheckbox.state == .on
        settings.showAlphanumericKeys = showAlphanumericCheckbox.state == .on
        settings.showSpecialKeys = showSpecialKeysCheckbox.state == .on
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

    private func saveHotkeys() {
        settings.mouseToggleHotkey = mouseHotkeyRecorder.hotkey
        settings.keyboardToggleHotkey = keyboardHotkeyRecorder.hotkey
        settings.drawingToggleHotkey = drawingHotkeyRecorder.hotkey
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }

    @objc private func closeWindow() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        mouseHotkeyRecorder.cancelRecording()
        keyboardHotkeyRecorder.cancelRecording()
        drawingHotkeyRecorder.cancelRecording()
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
