#!/bin/bash

# Configuration
SCHEME_NAME="ETPattern"
BUNDLE_ID="com.jackxhb.ETPattern"
CONFIGURATION="Debug"
BUILD_DIR="build"
TARGET_DEVICE_NAME="iPhone 17 Pro Max"

echo "🔍 Looking for $TARGET_DEVICE_NAME..."
# Auto-detect booted simulator or specific device
# Extract generic UUID format XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
DEVICE_ID=$(xcrun simctl list devices available | grep "$TARGET_DEVICE_NAME" | head -n 1 | sed -E 's/.*([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}).*/\1/')

if [ -z "$DEVICE_ID" ]; then
    echo "❌ Error: Could not find simulator '$TARGET_DEVICE_NAME'"
    exit 1
fi

# Check if booted
BOOT_STATUS=$(xcrun simctl list devices booted | grep "$DEVICE_ID")
if [ -z "$BOOT_STATUS" ]; then
    echo "🥾 Booting simulator: $TARGET_DEVICE_NAME ($DEVICE_ID)"
    xcrun simctl boot "$DEVICE_ID"
    echo "⏳ Waiting for simulator to boot..."
    xcrun simctl bootstatus "$DEVICE_ID" -b
else
    echo "✅ Simulator already booted: $DEVICE_ID"
fi

echo "🚀 Starting deployment to $TARGET_DEVICE_NAME ($DEVICE_ID)..."

# 1. Build using standard Xcode Scheme
echo "📦 Building $SCHEME_NAME..."

# Clean build
xcodebuild clean -scheme "$SCHEME_NAME" -destination "platform=iOS Simulator,id=$DEVICE_ID"

# Build and create .app in build/Debug-iphonesimulator/
xcodebuild -scheme "$SCHEME_NAME" \
           -destination "platform=iOS Simulator,id=$DEVICE_ID" \
           -configuration "$CONFIGURATION" \
           -derivedDataPath "$BUILD_DIR" \
           build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# 2. Locate the App Bundle
APP_PATH="$BUILD_DIR/Build/Products/Debug-iphonesimulator/ETPattern.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App bundle not found at $APP_PATH"
    exit 1
fi

echo "✅ Found App: $APP_PATH"

# 3. Uninstall existing app
echo "🗑️ Uninstalling existing app..."
xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true

# 4. Install the app to the simulator
echo "📲 Installing to simulator..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Successfully installed $SCHEME_NAME to Simulator!"
    echo "▶️ Launching app..."
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" -no-cloudkit
else
    echo "❌ Installation failed!"
    exit 1
fi
