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
- **Shortcut display.** Key combinations such as `⌘⇧4` or `⌃⌥→` appear as keycaps in a corner of the screen and fade
  out after a few seconds, as do clicks made with modifiers, such as `⌘ Click`. Keys are detected by physical position,
  so they are shown correctly with any keyboard layout.
- **Spotlight.** Dims the screen except a soft circle around the pointer, so the audience looks exactly where you point.
- **Zoom.** A round lens follows the pointer and enlarges what's under it, so small text and details are readable
  in a shared screen.
- **On-screen drawing.** Hold `⇧` and move the mouse to draw freehand, hold `⌃⇧` for straight lines, or `⇧⌘` for arrows. Drawings fade
  out automatically shortly after you release the keys.
- **Click-through overlay.** The overlay never takes focus or intercepts clicks, so you keep working normally.
- **Multiple displays.** Works on every connected display, and adapts when displays are connected, disconnected
  or rearranged. Shortcuts are shown on all displays, so they're visible whichever screen you share.
- **Menu bar only.** No Dock icon and no windows in the way. Everything is controlled from the menu bar or with global hotkeys.
- **Updates in the app.** Check for new versions from the menu, or at every start if you allow it. An update found at
  start only changes the menu bar icon, so no window appears in the middle of a presentation.
- **Customizable.** Colors, sizes, which keys to display, where to show them, the toggle hotkeys and the features that turn
  on at launch can all be changed in Settings, as well as the drawing color palette and the animation durations.

### See it in action

<table>
  <tr>
    <td align="center"><img src="docs/images/feature-mouse.gif" width="420" alt="Cursor highlighting with left and right clicks"><br>Cursor highlighting and clicks</td>
    <td align="center"><img src="docs/images/feature-keyboard.gif" width="420" alt="Shortcut keycaps"><br>Shortcut display</td>
  </tr>
  <tr>
    <td align="center"><img src="docs/images/feature-drawing.gif" width="420" alt="Freehand, line and arrow drawing with the color palette"><br>Drawing: freehand, line, arrow and the color palette</td>
    <td align="center"><img src="docs/images/feature-zoom.gif" width="420" alt="Zoom lens"><br>Zoom</td>
  </tr>
  <tr>
    <td align="center"><img src="docs/images/feature-spotlight.gif" width="420" alt="Spotlight"><br>Spotlight</td>
    <td></td>
  </tr>
</table>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/settings-dark.png">
    <img src="docs/images/settings-light.png" width="860" alt="Settings window: Mouse, Keyboard, Drawing, Hotkeys and General tabs, and Animation Durations">
  </picture>
</p>

## Requirements

- macOS 13.5 or later
- Accessibility permission (needed to observe global keyboard and mouse events; see [Privacy](#privacy))
- Screen Recording permission, only for Zoom
- To build from source: Xcode 16 or later

## Installation

### Download

1. Download `DaemonStraight-<version>.dmg` from the [latest release](https://github.com/shatalov-alex/DaemonStraight/releases/latest).
2. Open it and drag **DaemonStraight** to **Applications**.
3. Open the app. It isn't notarized by Apple, so the first time macOS says it can't verify the developer.
   Close the message, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
4. Grant Accessibility access (see [below](#granting-accessibility-access)).

The app runs on both Apple silicon and Intel Macs. To update later, use **Check for Updates...** in the menu.

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
   The Debug build is called **DaemonStraight Debug** and has its own bundle ID (`me.shatalov.DaemonStraight.debug`),
   so its permissions and settings are separate from an installed release.

To produce a standalone universal release build in `build/Release/`, run:

```bash
./scripts/build_release.sh
```

### Granting Accessibility access

On first launch, macOS asks you to allow DaemonStraight to control your computer. Open
**System Settings → Privacy & Security → Accessibility** and enable **DaemonStraight**. The app starts working within
a second, without a restart. Until then, the menu bar menu shows **Allow Accessibility Access…**, which opens that setting.

> [!NOTE]
> macOS ties this permission to the app's code signature. If you rebuild the app with a different (or ad-hoc)
> signature, remove the old entry from the list and grant access again. Releases after 1.1.0 share one
> certificate, so updating from one of them to a newer one keeps the permission.

## Usage

Toggle features from the menu bar icon or with the default hotkeys:

| Feature             | Hotkey  |
| ------------------- | ------- |
| Cursor highlighting | `⌃⌥⌘M`  |
| Shortcut display    | `⌃⌥⌘K`  |
| Drawing mode        | `⌃⌥⌘D`  |
| Spotlight           | `⌃⌥⌘S`  |
| Zoom                | `⌃⌥⌘Z`  |
| All features on/off | `⌃⌥⌘A`  |

While presenting:

| Action                                         | Hotkey          |
| ---------------------------------------------- | --------------- |
| Zoom in / out (with Zoom off: larger / smaller spotlight) | `⌃⌥⌘=` / `⌃⌥⌘-` |
| Larger / smaller zoom lens                     | `⌃⌥⌘]` / `⌃⌥⌘[` |
| Drawing color palette                          | `⌃⌥⌘C`          |
| Undo the last stroke                           | `⌃⌥⌘U`          |

Sizes changed with the hotkeys are saved, like the sliders in Settings.

The first time you turn on Zoom, macOS asks for the Screen Recording permission. Allow DaemonStraight in
**System Settings → Privacy & Security → Screen & System Audio Recording**, then restart the app if Zoom stays off.
**Turn All On** doesn't include Zoom, but **Turn All Off** turns it off too.

By default all features are off when the app starts. Choose the ones that turn on at launch in
**Settings → General → At Launch**.

### Tip: start and stop with your presentation

DaemonStraight is only needed while you present, so it works well with the **Shortcuts** app. Create one shortcut that
opens DaemonStraight (with the features you need turned on at launch), joins your next meeting and turns on a Focus mode,
and another one that quits DaemonStraight and turns the Focus mode off. Add both to the menu bar or the Dock, and the
whole setup is one click before and after the call.

DaemonStraight also adds two actions to Shortcuts:

- **Turn DaemonStraight Feature On or Off:** mouse highlighting, keyboard display, drawing mode, spotlight, zoom or all
  features; on, off or toggle. **All Features** works like **Turn All On** / **Turn All Off** in the menu.
- **Clear DaemonStraight Drawing**

So a shortcut can open the app and turn on just the features one kind of meeting needs.

> **Note:** macOS runs these two actions only for apps signed with an Apple developer certificate. The downloadable
> releases aren't yet, so there Shortcuts says that it "couldn't communicate with the app". Use links instead.

Links do the same and work in every build.

#### Set up links in Shortcuts

1. Open **Shortcuts** and open your shortcut, or click **+** for a new one.
2. Search the actions for **Open URLs** and double-click it.
3. Click the **URL** field and paste a link, for example `daemonstraight://mouse/on`.
4. Add another **Open URLs** action for each further feature.
5. Click **▶** to test. If macOS asks for permission, choose **Always Allow**.

You don't need an **Open App** action: the first link starts DaemonStraight. Put the links before the step that joins the
meeting, so the meeting window gets the focus last. In shortcuts that run by themselves use `on` and `off`, as the result
of `toggle` depends on the current state.

| Link                                  | What it does                                              |
| ------------------------------------- | --------------------------------------------------------- |
| `daemonstraight://<feature>/<state>`  | Turns a feature on or off, for example `daemonstraight://mouse/on` |
| `daemonstraight://clear`              | Clears the drawing                                        |

The features are `mouse`, `keyboard`, `drawing`, `spotlight`, `zoom` and `all`; the states are `on`, `off` and `toggle`.
Any app or web page can open a link, so while **Plain typing** is on in **Settings → Keyboard**, links can't turn the
shortcut display on (also not with `all/on`). They can always turn it off.

`all/on` doesn't include Zoom, `all/off` turns it off too. A link starts DaemonStraight if it isn't running, and the focus
stays in the app you're in.

| To do this                        | Use this link                |
| --------------------------------- | ---------------------------- |
| Cursor highlighting on            | `daemonstraight://mouse/on`     |
| Shortcut display on               | `daemonstraight://keyboard/on`  |
| Drawing mode on                   | `daemonstraight://drawing/on`   |
| Spotlight on                      | `daemonstraight://spotlight/on` |
| Zoom on                           | `daemonstraight://zoom/on`      |
| Everything on, except Zoom        | `daemonstraight://all/on`       |
| Everything off                    | `daemonstraight://all/off`      |
| Clear the drawing                 | `daemonstraight://clear`        |

### Drawing

While drawing mode is on:

| Action                     | How                                     |
| -------------------------- | --------------------------------------- |
| Freehand line              | Hold `⇧` and move the mouse             |
| Straight line              | Hold `⌃⇧` and move the mouse            |
| Arrow                      | Hold `⇧⌘` and move the mouse            |
| Switch line type mid-stroke | Press or release `⌃` or `⌘` while holding `⇧` |
| Keep drawings on screen    | Hold `⌘`, `⌥`, `⌃` or Caps Lock         |
| Clear immediately          | Menu bar → **Clear Drawing**            |
| Undo the last stroke       | `⌃⌥⌘U` or menu bar → **Undo Last Stroke** |
| Change the color           | `⌃⌥⌘C`, then the color's number (Esc or `⌃⌥⌘C` closes the palette); each stroke keeps its color |

Drawings fade out three seconds after you release `⇧` (by default, see **Animation Durations** below). With Caps Lock on they stay, including new ones, until you
turn Caps Lock off.

### Settings

Open **Settings…** from the menu bar icon (or press `⌘,` while the menu is open) to change:

- **Mouse:** ring colors (idle, left click, right click), diameter and ring width; spotlight diameter and dimming;
  zoom lens diameter and magnification
- **Keyboard:** which keys the shortcut display shows (modifiers, function keys, special keys, clicks with modifiers
  and, optionally, plain typing), the screen corner and the key size
- **Drawing:** line color and width, the palette colors (up to 9), and whether a color picked from the palette is kept
  (by default drawing goes back to the line color when drawing mode is turned off)
- **Hotkeys:** the toggle hotkeys and the ones used while presenting (each must include at least one of `⌃`, `⌥` or `⌘`)
- **General:** the features that turn on at launch
  and whether to check for updates when the app starts
- **Animation Durations** (the triangle at the bottom of the window): how long the mouse click animation, the ring
  fading in and out, keycaps on screen and their slide, drawings on screen and their fade take

Changes apply immediately and are saved automatically.

## Privacy

DaemonStraight observes keyboard and mouse events only to draw the overlay in real time.

- Pressed keys are **never written to logs or disk** and are kept in memory only while they are on screen.
- The app connects to the network **only to check for updates**, when you choose **Check for Updates...** or allow
  checks at start (it asks once, and you can change this in **Settings → General**). It then downloads a small file with
  the latest version number from this project's GitHub releases. No personal data or usage statistics are sent;
  as with any download, GitHub can see your IP address.
- Updates are installed only after you confirm them, and their signature is checked first. They are handled by a
  helper from the [Sparkle](https://sparkle-project.org) framework; the app itself has no network permission.
- Zoom shows a live picture of the screen around the pointer. The picture is only displayed in the lens: it's never
  saved, recorded or sent anywhere, and the screen isn't captured at all while Zoom is off.
- Settings are stored locally in the app's preferences (`UserDefaults`).

### Verifying a download

Releases are signed with a self-signed certificate: [`Config/release-certificate.pem`](Config/release-certificate.pem).
It doesn't replace Apple's notarization, but you can check that an app comes from this project:

```bash
codesign -d -r- /Applications/DaemonStraight.app
```

The output must contain `f691fccd86582aa17b5ec5a6cf598b8a857e531e`, the certificate's SHA-1 fingerprint.

## Project structure

```
DaemonStraight/
├── main.swift                       App entry point (menu bar app, no Dock icon)
├── AppDelegate.swift                Status bar menu, global hotkeys, overlay window
├── ViewController.swift             Event monitoring, shortcut filtering, drawing control
├── TransparentOverlayWindow.swift   Full-screen, click-through overlay window (one per display)
├── CircleView.swift                 Cursor highlight rings and click animation
├── SpotlightView.swift              Dimmed screen with a circle around the cursor
├── ZoomView.swift                   Magnifying lens around the cursor (ScreenCaptureKit)
├── DrawView.swift                   Drawing canvas with fade-out
├── ColorPalettePanel.swift          Numbered drawing colors
├── URLCommand.swift                 daemonstraight:// links
├── ShortcutsIntents.swift           Actions for the Shortcuts app
├── ShortcutPressedViewContainer.swift, ShortcutPressedView.swift,
│   ButtonView.swift, BlurredView.swift, KeyShape.swift, KeyMapping.swift
│                                    Keycap rendering for the shortcut display
├── UpdateManager.swift              Update checks (Sparkle)
├── SettingsManager.swift            Persistent settings
└── SettingsWindowController.swift   Settings window and hotkey recorder
scripts/
├── build_release.sh                 Universal (Apple silicon + Intel) release build
├── release.sh                       Versions, tags, packages and publishes a release
├── verify_release.sh                Self-check of the app and packages before publishing
├── create_signing_certificate.sh    Creates the release certificate (run once)
├── capture_media.sh, media/         Makes the screenshots and recordings of this README
└── generate_icons.py                Generates the app and menu bar icons (requires Pillow)
```

## Versioning

DaemonStraight follows [Semantic Versioning](https://semver.org): releases are tagged `vMAJOR.MINOR.PATCH`, and every
change is listed in the [changelog](CHANGELOG.md). Maintainers publish a release with `./scripts/release.sh X.Y.Z`.

## Contributing

Bug reports and pull requests are welcome. For larger changes, please open an issue first to discuss what you would
like to change.

## License

DaemonStraight is released under the [MIT License](LICENSE).
