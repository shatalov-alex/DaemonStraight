#!/bin/bash

# DaemonStraight Release Build Script
# Creates a production-ready build of the application

set -e  # Exit on error

# Run from the repository root regardless of where the script is called from
cd "$(dirname "$0")/.."

echo "🚀 Building DaemonStraight for Release..."
echo ""

DERIVED_DATA="build/derived"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project DaemonStraight.xcodeproj -scheme DaemonStraight -configuration Release -derivedDataPath "$DERIVED_DATA"
rm -rf build/Release

# Build the app in Release mode
# Strip symbols and map source paths so the binary doesn't contain local build paths
echo "🔨 Building Release configuration..."
xcodebuild build \
    -project DaemonStraight.xcodeproj \
    -scheme DaemonStraight \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$DERIVED_DATA" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    DEPLOYMENT_POSTPROCESSING=YES \
    STRIP_INSTALLED_PRODUCT=YES \
    OTHER_SWIFT_FLAGS="-file-prefix-map $PWD/=" \
    DEBUG_INFORMATION_FORMAT=dwarf-with-dsym

# Find the built app
BUILD_DIR="build/Release"
APP_PATH="$BUILD_DIR/DaemonStraight.app"
mkdir -p "$BUILD_DIR"
ditto "$DERIVED_DATA/Build/Products/Release/DaemonStraight.app" "$APP_PATH"

if [ -d "$APP_PATH" ]; then
    # Sign with the release certificate, so the Accessibility permission survives updates.
    # Without it (see create_signing_certificate.sh) the signature is ad-hoc
    SIGN_IDENTITY="DaemonStraight Self-Signed"
    if ! security find-identity -p codesigning | grep -q "\"$SIGN_IDENTITY\""; then
        echo "⚠️  \"$SIGN_IDENTITY\" not found, signing ad-hoc"
        SIGN_IDENTITY="-"
    fi

    # Sparkle's helpers are signed from the inside out, as Sparkle's documentation describes
    SPARKLE="$APP_PATH/Contents/Frameworks/Sparkle.framework"
    codesign --force --sign "$SIGN_IDENTITY" --timestamp=none -o runtime "$SPARKLE/Versions/B/XPCServices/Installer.xpc"
    codesign --force --sign "$SIGN_IDENTITY" --timestamp=none -o runtime --preserve-metadata=entitlements "$SPARKLE/Versions/B/XPCServices/Downloader.xpc"
    codesign --force --sign "$SIGN_IDENTITY" --timestamp=none -o runtime "$SPARKLE/Versions/B/Autoupdate"
    codesign --force --sign "$SIGN_IDENTITY" --timestamp=none -o runtime "$SPARKLE/Versions/B/Updater.app"
    codesign --force --sign "$SIGN_IDENTITY" --timestamp=none -o runtime "$SPARKLE"

    # Re-sign without the debugger (get-task-allow) entitlement, keeping the App Sandbox ones
    ENTITLEMENTS="$(mktemp)"
    codesign -d --entitlements - --xml "$APP_PATH" > "$ENTITLEMENTS" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Delete :com.apple.security.get-task-allow" "$ENTITLEMENTS" 2>/dev/null || true
    codesign --force --sign "$SIGN_IDENTITY" --timestamp=none --entitlements "$ENTITLEMENTS" "$APP_PATH"
    rm -f "$ENTITLEMENTS"

    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📦 Application built at:"
    echo "   $APP_PATH"
    echo ""
    echo "📏 Application size:"
    du -sh "$APP_PATH"
    echo ""
    echo "🎯 To run the app:"
    echo "   open $APP_PATH"
    echo ""
    echo "📤 To distribute, copy the app or zip it:"
    echo "   ditto -c -k --keepParent $APP_PATH DaemonStraight.zip"
else
    echo ""
    echo "❌ Build failed - app not found at expected location"
    exit 1
fi
