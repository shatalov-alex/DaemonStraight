# Changelog

All notable changes to DaemonStraight are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html):
**major** for incompatible changes, **minor** for new features, **patch** for bug fixes.

## [Unreleased]

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

[Unreleased]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/shatalov-alex/DaemonStraight/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/shatalov-alex/DaemonStraight/releases/tag/v1.0.0
