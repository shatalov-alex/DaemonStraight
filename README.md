<p align="center">
  <img src="DaemonStraight/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="DaemonStraight icon">
</p>

<h1 align="center">DaemonStraight</h1>

<p align="center">
  A lightweight macOS menu bar app that makes live demos and screen sharing easier to follow:<br>
  it highlights the cursor, shows the shortcuts you press, and lets you draw on top of the screen.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013.5%2B-lightgrey" alt="Platform: macOS 13.5+">
  <img src="https://img.shields.io/badge/Swift-5-orange" alt="Swift 5">
  <img src="https://img.shields.io/badge/UI-AppKit-blue" alt="AppKit">
  <a href="https://github.com/shatalov-alex/DaemonStraight/releases/latest"><img src="https://img.shields.io/github/v/release/shatalov-alex/DaemonStraight" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT"></a>
</p>

---

## Features

- **Cursor highlighting.** A soft, glowing double ring follows the pointer. Pressing a mouse button shrinks the ring
  and changes its color (separate colors for left and right clicks), so viewers can see every click.
- **Shortcut display.** Key combinations such as `⌘⇧4` or `⌃⌥→` appear as keycaps in the corner of the screen and fade
  out after a few seconds. Keys are detected by physical position, so they are shown correctly with any keyboard layout.
- **On-screen drawing.** Hold `⇧` and move the mouse to draw freehand, or hold `⌃⇧` for straight lines. Drawings fade
  out automatically shortly after you release the keys.
- **Click-through overlay.** The overlay never takes focus or intercepts clicks, so you keep working normally.
- **Multiple displays.** Works on every connected display, and adapts when displays are connected, disconnected
  or rearranged. Shortcuts are shown on all displays, so they're visible whichever screen you share.
- **Menu bar only.** No Dock icon and no windows in the way. Everything is controlled from the menu bar or with global hotkeys.
- **Customizable.** Colors, sizes, which keys to display, and the toggle hotkeys can all be changed in Settings.

<p align="center">
  <img src="docs/images/settings-light.png" width="480" alt="Settings window">
</p>

## Requirements

- macOS 13.5 or later
- Accessibility permission (needed to observe global keyboard and mouse events; see [Privacy](#privacy))
- To build from source: Xcode 16 or later

## Installation

### Download

1. Download `DaemonStraight-<version>.dmg` from the [latest release](https://github.com/shatalov-alex/DaemonStraight/releases/latest).
2. Open it and drag **DaemonStraight** to **Applications**.
3. Open the app. It isn't notarized by Apple, so the first time macOS says it can't verify the developer.
   Close the message, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
4. Grant Accessibility access (see [below](#granting-accessibility-access)).

The app runs on both Apple silicon and Intel Macs.

### Build from source

1. Clone the repository:
   ```bash
   git clone https://github.com/shatalov-alex/DaemonStraight.git
   cd DaemonStraight
   ```
2. Set your Apple Developer team for code signing by creating `Config/Local.xcconfig` (ignored by git):
   ```bash
   echo 'DEVELOPMENT_TEAM = YOUR_TEAM_ID' > Config/Local.xcconfig
   ```
   Your team ID is shown in Xcode under **Settings → Accounts**, or at
   [developer.apple.com/account](https://developer.apple.com/account).
3. Open `DaemonStraight.xcodeproj` in Xcode and press **⌘R** to build and run.

To produce a standalone universal release build in `build/Release/`, run:

```bash
./scripts/build_release.sh
```

### Granting Accessibility access

On first launch, macOS asks you to allow DaemonStraight to control your computer. Open
**System Settings → Privacy & Security → Accessibility** and enable **DaemonStraight**, then restart the app.

> [!NOTE]
> macOS ties this permission to the app's code signature. If you rebuild the app with a different (or ad-hoc)
> signature, remove the old entry from the list and grant access again.

## Usage

All features are off when the app starts. Toggle them from the menu bar icon or with the default hotkeys:

| Feature             | Hotkey  |
| ------------------- | ------- |
| Cursor highlighting | `⌃⌥⌘M`  |
| Shortcut display    | `⌃⌥⌘K`  |
| Drawing mode        | `⌃⌥⌘D`  |

### Drawing

While drawing mode is on:

| Action                     | How                                     |
| -------------------------- | --------------------------------------- |
| Freehand line              | Hold `⇧` and move the mouse             |
| Straight line              | Hold `⌃⇧` and move the mouse            |
| Switch line type mid-stroke | Press or release `⌃` while holding `⇧` |
| Keep drawings on screen    | Hold `⌘`, `⌥`, `⌃` or Caps Lock         |
| Clear immediately          | Menu bar → **Clear Drawing**            |

Drawings fade out three seconds after you release `⇧`.

### Settings

Open **Settings…** from the menu bar icon (or press `⌘,` while the menu is open) to change:

- ring colors (idle, left click, right click), diameter and ring width
- drawing color and line width
- which keys the shortcut display shows: modifiers, function keys, special keys (Esc, Tab, Return, Delete, arrows)
  and, optionally, plain typing
- the three toggle hotkeys (each must include at least one of `⌃`, `⌥` or `⌘`)

Changes apply immediately and are saved automatically.

## Privacy

DaemonStraight observes keyboard and mouse events only to draw the overlay in real time.

- Pressed keys are **never written to logs or disk** and are kept in memory only while they are on screen.
- The app makes **no network connections**.
- Settings are stored locally in the app's preferences (`UserDefaults`).

## Project structure

```
DaemonStraight/
├── main.swift                       App entry point (menu bar app, no Dock icon)
├── AppDelegate.swift                Status bar menu, global hotkeys, overlay window
├── ViewController.swift             Event monitoring, shortcut filtering, drawing control
├── TransparentOverlayWindow.swift   Full-screen, click-through overlay window (one per display)
├── CircleView.swift                 Cursor highlight rings and click animation
├── DrawView.swift                   Drawing canvas with fade-out
├── ShortcutPressedViewContainer.swift, ShortcutPressedView.swift,
│   ButtonView.swift, BlurredView.swift, KeyShape.swift, KeyMapping.swift
│                                    Keycap rendering for the shortcut display
├── SettingsManager.swift            Persistent settings
└── SettingsWindowController.swift   Settings window and hotkey recorder
scripts/
├── build_release.sh                 Universal (Apple silicon + Intel) release build
└── generate_icons.py                Generates the app and menu bar icons (requires Pillow)
```

## Contributing

Bug reports and pull requests are welcome. For larger changes, please open an issue first to discuss what you would
like to change.

## License

DaemonStraight is released under the [MIT License](LICENSE).
