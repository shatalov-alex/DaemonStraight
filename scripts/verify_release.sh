#!/bin/bash

# DaemonStraight Release Self-Check
# Checks the built app and the release packages before anything is published.
#
# Usage: ./scripts/verify_release.sh X.Y.Z [packages-folder]   (default folder: build/dist)

cd "$(dirname "$0")/.."

VERSION="$1"
DIST="${2:-build/dist}"
APP_PATH="build/Release/DaemonStraight.app"
ZIP="$DIST/DaemonStraight-$VERSION.zip"
CERT_SHA1="F691FCCD86582AA17B5EC5A6CF598B8A857E531E"
SIGN_UPDATE="build/derived/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
FAILED=0

check() {
    local title="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "✅ $title"
    else
        echo "❌ $title"
        FAILED=1
    fi
}

plist_value() { /usr/libexec/PlistBuddy -c "Print $2" "$1/Contents/Info.plist"; }
has_version() { [ "$(plist_value "$1" CFBundleShortVersionString)" = "$VERSION" ]; }
signature_valid() { codesign --verify --deep --strict "$1"; }
has_release_certificate() { codesign -d -r- "$1" 2>&1 | grep -qi "$CERT_SHA1"; }
has_no_team_id() { codesign -dvv "$1" 2>&1 | grep -q '^TeamIdentifier=not set'; }
is_universal() { local archs; archs="$(lipo -archs "$1/Contents/MacOS/DaemonStraight")"; [[ "$archs" == *x86_64* && "$archs" == *arm64* ]]; }
entitlements() { codesign -d --entitlements - --xml "$1" 2>/dev/null; }
is_sandboxed() { entitlements "$1" | grep -q 'com.apple.security.app-sandbox'; }
has_no_network_permission() { ! entitlements "$1" | grep -q 'com.apple.security.network'; }
has_no_debug_entitlement() { ! entitlements "$1" | grep -q 'get-task-allow'; }
has_no_local_paths() { ! grep -rqa "$HOME" "$1"; }

# The team ID stays private, so it's read from the ignored local settings
has_no_private_team_id() {
    local team
    team="$(sed -n 's/^DEVELOPMENT_TEAM *= *//p' Config/Local.xcconfig 2>/dev/null)"
    [ -z "$team" ] || ! grep -rqa "$team" "$1"
}

check_app() {
    check "$2: version $VERSION" has_version "$1"
    check "$2: signature is valid" signature_valid "$1"
    check "$2: signed with the release certificate" has_release_certificate "$1"
    check "$2: no team ID in the signature" has_no_team_id "$1"
    check "$2: universal" is_universal "$1"
    check "$2: App Sandbox on" is_sandboxed "$1"
    check "$2: no network permission on the app" has_no_network_permission "$1"
    check "$2: no debug entitlement" has_no_debug_entitlement "$1"
    check "$2: no local paths" has_no_local_paths "$1"
    check "$2: no private team ID" has_no_private_team_id "$1"
}

feed_value() { sed -n "s/.*$1=\"\([^\"]*\)\".*/\1/p" "$DIST/appcast.xml" | head -1; }
feed_is_valid() { xmllint --noout "$DIST/appcast.xml"; }
feed_has_version() { grep -q "<sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>" "$DIST/appcast.xml"; }
feed_links_to_zip() { [ "$(feed_value url)" = "https://github.com/shatalov-alex/DaemonStraight/releases/download/v$VERSION/DaemonStraight-$VERSION.zip" ]; }
feed_has_zip_size() { [ "$(feed_value length)" = "$(stat -f %z "$ZIP")" ]; }
update_signature_valid() { "$SIGN_UPDATE" --verify "$ZIP" "$(feed_value 'sparkle:edSignature')"; }
checksums_match() { (cd "$DIST" && shasum -a 256 -c SHA256SUMS.txt); }

echo "🔎 Self-check for $VERSION"
check_app "$APP_PATH" "App"

UNPACKED="$(mktemp -d)"
trap 'rm -rf "$UNPACKED"' EXIT
if ditto -x -k "$ZIP" "$UNPACKED" 2>/dev/null; then
    check_app "$UNPACKED/DaemonStraight.app" "ZIP"
else
    echo "❌ ZIP: can't be unpacked"
    FAILED=1
fi

check "Feed: valid XML" feed_is_valid
check "Feed: version $VERSION" feed_has_version
check "Feed: links to the ZIP of this release" feed_links_to_zip
check "Feed: ZIP size matches" feed_has_zip_size
check "Feed: update signature is valid" update_signature_valid
check "Checksums match" checksums_match

if [ "$FAILED" != 0 ]; then
    echo "❌ Self-check failed"
    exit 1
fi
echo "✅ Self-check passed"
