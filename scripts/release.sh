#!/bin/bash

# DaemonStraight Release Script
# Publishes a new version: sets the version, updates CHANGELOG.md, commits, tags vX.Y.Z,
# builds the universal app, packages DMG + ZIP and creates the GitHub release.
#
# Usage: ./scripts/release.sh X.Y.Z
#
# Versions follow Semantic Versioning (https://semver.org):
#   MAJOR - incompatible changes, MINOR - new features, PATCH - bug fixes.
# Describe the changes under "## [Unreleased]" in CHANGELOG.md before running.

set -e  # Exit on error

# Run from the repository root regardless of where the script is called from
cd "$(dirname "$0")/.."

VERSION="$1"
TAG="v$VERSION"
REPO="shatalov-alex/DaemonStraight"
DIST="build/dist"

fail() { echo "❌ $1"; exit 1; }

# Authenticate git over HTTPS with the GitHub CLI login
git_push() { git -c credential.helper= -c credential.helper='!gh auth git-credential' push "$@"; }

# MARK: - Checks
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Usage: $0 X.Y.Z (semantic version, e.g. 1.2.0)"
command -v gh >/dev/null || fail "GitHub CLI (gh) is required"
[ "$(git branch --show-current)" = "main" ] || fail "Releases are made from main"
[ -z "$(git status --porcelain)" ] || fail "Working tree has uncommitted changes"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && fail "Tag $TAG already exists"

git fetch -q origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || fail "main is not in sync with origin/main"

LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
if [ -n "$LAST_TAG" ]; then
    # The new version must be greater than the last released one
    [ "$(printf '%s\n%s\n' "${LAST_TAG#v}" "$VERSION" | sort -V | tail -1)" = "$VERSION" ] && [ "${LAST_TAG#v}" != "$VERSION" ] \
        || fail "$VERSION must be greater than the last release ${LAST_TAG#v}"
fi

# MARK: - Changelog
# Move the "Unreleased" notes under the new version and update the comparison links
NOTES="$(mktemp)"
python3 - "$VERSION" "$(date +%Y-%m-%d)" "$REPO" "$NOTES" <<'EOF'
import re, sys
version, date, repo, notes_path = sys.argv[1:]
text = open("CHANGELOG.md").read()

match = re.search(r"^## \[Unreleased\]\n(.*?)(?=^## \[|^\[Unreleased\]:)", text, re.S | re.M)
notes = match.group(1).strip() if match else ""
if not notes:
    sys.exit("❌ CHANGELOG.md has no changes under ## [Unreleased]")

text = text.replace(match.group(0), f"## [Unreleased]\n\n## [{version}] - {date}\n\n{notes}\n\n", 1)
previous = re.search(r"^\[Unreleased\]: .*compare/(v[^.]+\.[^.]+\.[^.]+)\.\.\.HEAD$", text, re.M)
text = re.sub(r"^\[Unreleased\]: .*$",
              f"[Unreleased]: https://github.com/{repo}/compare/v{version}...HEAD\n"
              f"[{version}]: https://github.com/{repo}/compare/{previous.group(1)}...v{version}" if previous else
              f"[Unreleased]: https://github.com/{repo}/compare/v{version}...HEAD\n"
              f"[{version}]: https://github.com/{repo}/releases/tag/v{version}",
              text, count=1, flags=re.M)
open("CHANGELOG.md", "w").write(text)
open(notes_path, "w").write(notes + "\n")
EOF

# MARK: - Version
# Marketing version = X.Y.Z, build number increases with every release
BUILD_NUMBER=$(( $(grep -m1 -o 'CURRENT_PROJECT_VERSION = [0-9]*' DaemonStraight.xcodeproj/project.pbxproj | grep -o '[0-9]*$') + 1 ))
sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $VERSION;/; s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/" \
    DaemonStraight.xcodeproj/project.pbxproj

echo "🏷️  Releasing $VERSION (build $BUILD_NUMBER)"

# MARK: - Build & Package
./scripts/build_release.sh

APP_PATH="build/Release/DaemonStraight.app"
built_version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
[ "$built_version" = "$VERSION" ] || fail "Built app has version $built_version, expected $VERSION"

rm -rf "$DIST" && mkdir -p "$DIST/dmg"
ditto "$APP_PATH" "$DIST/dmg/DaemonStraight.app"
ln -s /Applications "$DIST/dmg/Applications"
hdiutil create -volname "DaemonStraight" -srcfolder "$DIST/dmg" -ov -format UDZO -quiet "$DIST/DaemonStraight-$VERSION.dmg"
ditto -c -k --keepParent "$APP_PATH" "$DIST/DaemonStraight-$VERSION.zip"
rm -rf "$DIST/dmg"
(cd "$DIST" && shasum -a 256 "DaemonStraight-$VERSION.dmg" "DaemonStraight-$VERSION.zip" > SHA256SUMS.txt)

# MARK: - Commit, Tag & Publish
git add CHANGELOG.md DaemonStraight.xcodeproj/project.pbxproj
git commit -q -m "Release $VERSION"
git tag -a "$TAG" -m "DaemonStraight $VERSION"
git_push -q origin main "$TAG"

cat >> "$NOTES" <<EOF

## Installation

1. Download **DaemonStraight-$VERSION.dmg** below, open it and drag **DaemonStraight** to **Applications**.
2. Open the app. It isn't notarized by Apple, so the first time macOS says it can't verify the developer. Close the message, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
3. When asked, enable DaemonStraight in **System Settings → Privacy & Security → Accessibility**, then restart the app.

Requires macOS 13.5 or later. Universal app for Apple silicon and Intel Macs.

## Checksums (SHA-256)

\`\`\`
$(cat "$DIST/SHA256SUMS.txt")
\`\`\`
EOF

# The tag is already pushed at this point; retry if GitHub has a temporary error
for attempt in 1 2 3; do
    if gh release create "$TAG" -R "$REPO" --title "DaemonStraight $VERSION" --notes-file "$NOTES" --verify-tag --latest \
        "$DIST/DaemonStraight-$VERSION.dmg" "$DIST/DaemonStraight-$VERSION.zip" "$DIST/SHA256SUMS.txt"; then
        break
    fi
    [ "$attempt" -lt 3 ] || fail "Creating the GitHub release failed. Notes are in $NOTES - rerun the gh release create step"
    echo "⚠️  Creating the GitHub release failed, retrying in 10 s..."
    gh release delete "$TAG" -R "$REPO" --yes >/dev/null 2>&1 || true  # remove a partly created release, keep the tag
    sleep 10
done
rm -f "$NOTES"

echo ""
echo "✅ Released $TAG: https://github.com/$REPO/releases/tag/$TAG"
