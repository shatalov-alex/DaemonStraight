#!/bin/bash

# DaemonStraight Release Build Script
# Creates a production-ready build of the application

set -e  # Exit on error

# Run from the repository root regardless of where the script is called from
cd "$(dirname "$0")/.."

echo "🚀 Building DaemonStraight for Release..."
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project DaemonStraight.xcodeproj -configuration Release

# Build the app in Release mode
echo "🔨 Building Release configuration..."
xcodebuild build \
    -project DaemonStraight.xcodeproj \
    -configuration Release \
    -arch x86_64 \
    -arch arm64 \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO

# Find the built app
BUILD_DIR="build/Release"
APP_PATH="$BUILD_DIR/DaemonStraight.app"

if [ -d "$APP_PATH" ]; then
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
