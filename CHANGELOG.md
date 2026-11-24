# Changelog

All notable changes to DaemonStraight are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html):
**major** for incompatible changes, **minor** for new features, **patch** for bug fixes.

## [Unreleased]

### Added

- Links that turn features on or off and clear the drawing, such as `daemonstraight://mouse/on` (see the README). Use
  them with the **Open URLs** action of Shortcuts: they work in every build.

### Known issues

- The Shortcuts actions added in 1.4.0 fail in the downloadable releases ("Shortcuts couldn't communicate with the
  app"): macOS runs them only for apps signed with an Apple developer certificate. Use the links instead.

## [1.4.0] - 2026-11-17

### Added

- Arrows: hold `⇧⌘` and move the mouse while drawing mode is on. Like straight lines, they can be switched to and from
  in the middle of a stroke.
- Undo the last stroke with `⌃⌥⌘U` (can be changed in Settings › Hotkeys) or from the menu.
- Shortcuts actions: **Turn DaemonStraight Feature On or Off** (any feature or all of them; on, off or toggle) and
  **Clear DaemonStraight Drawing**.
- Hotkeys while presenting: `⌃⌥⌘=` / `⌃⌥⌘-` zoom in and out (with Zoom off, they make the spotlight larger or
  smaller), `⌃⌥⌘]` / `⌃⌥⌘[` change the zoom lens size. The new sizes are saved.
- Drawing color palette: `⌃⌥⌘C` shows up to 9 numbered colors (chosen in Settings › Drawing); press a number (or click
  a color) to draw with it, Esc or `⌃⌥⌘C` closes it. The number isn't typed into the app in front. Each stroke keeps
  its color. A setting decides whether the picked color is kept or drawing goes back to the line color when drawing
  mode is turned off.
- A **Hotkeys** tab in Settings with all hotkeys; hotkeys with punctuation, Space, Return, Tab, Delete, navigation keys,
  F13–F20 and keypad keys are shown by name instead of `?`.
- README: new settings screenshots and short recordings of each feature.
- The cursor ring fades in and out when mouse highlighting is turned on or off.
- **Animation Durations** in Settings (the triangle at the bottom of the window): the mouse click animation, the ring
  fade, how long keycaps stay and slide, and how long drawings stay and fade. The defaults are the previous durations.

### Fixed

- With Caps Lock on, a new stroke made all drawings fade three seconds later. Now they stay until Caps Lock is off.
- Pressing `⇧` without moving the mouse (typing capitals while drawing mode is on) no longer restarts the fade countdown.
- The cursor ring no longer stays pressed after a click on the app's menu or Settings window.
- After switching from freehand to a straight line mid-stroke, the line now starts where the freehand part ends, as it is
  shown while drawing.

## [1.3.1] - 2026-11-17

### Fixed

- Opening the app from Shortcuts or Spotlight no longer takes the focus from the app you're in. Before, key presses
  then went to DaemonStraight: macOS beeped, and drawing and the shortcut display didn't react until you clicked
  somewhere. The focus also goes back after you close Settings.
- Hotkeys no longer make macOS beep when DaemonStraight is the active app.
- Without the Accessibility permission, the app no longer shows its own alert at launch (it took the focus). The menu
  shows **Allow Accessibility Access…** instead, and the app starts working as soon as access is granted, without a restart.

### Changed

- The Debug build has its own bundle ID, so running it doesn't affect the permissions of an installed release.

## [1.3.0] - 2026-11-17

### Added

- Zoom (`⌃⌥⌘Z`): a round lens that follows the pointer and enlarges what's under it. Diameter and magnification
  are adjustable in Settings. Zoom needs the Screen Recording permission, which macOS asks for the first time.

## [1.2.1] - 2026-11-05

### Fixed

- App startup no longer relies on code that the Swift 6 language mode would reject. Nothing changes in how the app works.

## [1.2.0] - 2026-11-05

### Added

- Check for Updates menu item, using the [Sparkle](https://sparkle-project.org) framework. Updates are installed only
  after you confirm them.
- Optional check for updates when the app starts. The app asks once, and it can be changed in Settings › General.
  An update found this way only changes the menu bar icon, so no window appears during a presentation.

### Changed

- The app now connects to the network to check for updates, if you allow it or use the menu item.
- Releases are signed with a permanent self-signed certificate, so future updates keep the Accessibility permission.
  It has to be granted once more when updating to this version.

## [1.1.0] - 2026-11-04

### Added

- Spotlight mode (`⌃⌥⌘S`): dims the display with the pointer except a soft circle around it.
  Diameter and dimming are adjustable in Settings.
- Mouse clicks made with modifiers, such as `⌘ Click` or `⌥ Right Click`, are shown next to the shortcuts.
  Plain clicks are never shown.
- Choice of screen corner and key size for the shortcut display.
- Toggle All hotkey (`⌃⌥⌘A`) and menu item that turn all features on or off at once.
- Settings › General › At Launch: choose which features turn on when the app starts.

### Changed

- The Settings window is organized in tabs: Mouse, Keyboard, Drawing and General.

### Fixed

- Arrow, function and navigation keys are no longer shown with an extra "fn" keycap.
- Home, End, Page Up and Page Down are shown as special keys.

## [1.0.0] - 2026-11-03

### Added

- Cursor highlighting with separate colors for left and right clicks.
- Shortcut display with keycaps, independent of the keyboard layout.
- On-screen drawing: freehand with `⇧`, straight lines with `⌃⇧`; drawings fade out automatically.
- Support for multiple displays.
- Settings for colors, sizes, displayed keys and toggle hotkeys.

[Unreleased]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.3.1...v1.4.0
[1.3.1]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/shatalov-alex/DaemonStraight/releases/tag/v1.0.0
