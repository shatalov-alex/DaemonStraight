#!/bin/bash

# DaemonStraight README Media
# Makes the settings screenshots and the feature recordings of the README from the app's own views, on a neutral
# canvas. Only its own windows are captured, so it needs no permission and shows nothing else on the screen.
# The windows appear on the screen for about a minute: don't touch them.
#
# Usage: ./scripts/capture_media.sh [mouse|keyboard|drawing|spotlight|zoom|settings]   (default: everything)
# The files go to build/media. Look at them, then copy them to docs/images.

set -e  # Exit on error

# Run from the repository root regardless of where the script is called from
cd "$(dirname "$0")/.."

OUT="build/media"
mkdir -p "$OUT"

# The app's views and settings, without the parts that start the app
SOURCES=()
for file in DaemonStraight/*.swift; do
    case "$(basename "$file")" in
        main.swift|AppDelegate.swift|UpdateManager.swift|ShortcutsIntents.swift|URLCommand.swift|ViewController.swift) ;;
        *) SOURCES+=("$file") ;;
    esac
done

# macOS 14: the window capture function isn't available to apps built for later versions
swiftc -O -swift-version 5 -suppress-warnings -target "$(uname -m)-apple-macos14.0" -module-name DSCapture \
    "${SOURCES[@]}" scripts/media/main.swift -o "$OUT/dscapture"
"$OUT/dscapture" "$OUT" "$@" 2>/dev/null
rm -f "$OUT/dscapture"

echo "✅ Done: $OUT"
