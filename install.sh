#!/usr/bin/env bash

# ETPattern Universal Install Script
# Automatically selects between connected device and simulator.

set -euo pipefail

# Configuration
PROJECT_NAME="ETPattern"
SCHEME="ETPattern"
BUNDLE_ID="com.jackxhb.ETPattern"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$ROOT_DIR/${PROJECT_NAME}.xcodeproj"

echo "🔍 Identifying target destination..."

# 1. Check for connected physical iPhone
DEVICE_LIST="$(xcrun devicectl list devices)"
CONNECTED_IPHONE_ID="$(echo "$DEVICE_LIST" | grep "iPhone" | grep "connected" | awk '{print $3}' | head -n 1 || echo "")"

DESTINATION=""
DESTINATION_ID=""
DEVICE_TYPE=""
SDK=""

if [[ -n "$CONNECTED_IPHONE_ID" ]]; then
    DESTINATION_ID="$CONNECTED_IPHONE_ID"
    DEVICE_TYPE="physical"
    DESTINATION="platform=iOS,id=$DESTINATION_ID"
    SDK="iphoneos"
    echo "📱 Found physical device: $DESTINATION_ID"
else
    # 2. Check for booted simulator
    BOOTED_SIM="$(xcrun simctl list devices booted | grep "iPhone" | head -n 1 || true)"
    if [[ -n "$BOOTED_SIM" ]]; then
        DESTINATION_ID="$(echo "$BOOTED_SIM" | sed -n 's/.*(\([0-9A-F-]*\)).*/\1/p')"
        DEVICE_TYPE="simulator"
        DESTINATION="platform=iOS Simulator,id=$DESTINATION_ID"
        SDK="iphonesimulator"
        echo "💻 Found booted simulator: $DESTINATION_ID"
    else
        # 3. Fallback to default simulator
        IPHONE_SIM="$(xcrun simctl list devices available | grep -E "iPhone 17|iPhone 16" | head -n 1 || true)"
        if [[ -z "$IPHONE_SIM" ]]; then
            echo "❌ No suitable device or simulator found."
            exit 1
        fi
        DESTINATION_ID="$(echo "$IPHONE_SIM" | sed -n 's/.*(\([0-9A-F-]*\)).*/\1/p')"
        echo "🚀 Booting simulator: $DESTINATION_ID"
        xcrun simctl boot "$DESTINATION_ID" || true
        DEVICE_TYPE="simulator"
        DESTINATION="platform=iOS Simulator,id=$DESTINATION_ID"
        SDK="iphonesimulator"
    fi
fi

# 4. Build
echo "📦 Building for $SDK..."
xcodebuild -project "$PROJECT_PATH" \
           -scheme "$SCHEME" \
           -sdk "$SDK" \
           -configuration Debug \
           -destination "$DESTINATION" \
           -derivedDataPath "build" \
           build | xcbeautify || xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -sdk "$SDK" -configuration Debug -destination "$DESTINATION" -derivedDataPath "build" build

# 5. Extract App Path
BUILD_SETTINGS="$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -sdk "$SDK" -showBuildSettings -destination "$DESTINATION")"
TARGET_BUILD_DIR="$(echo "$BUILD_SETTINGS" | grep TARGET_BUILD_DIR | sed 's/.*= //' | xargs)"
WRAPPER_NAME="$(echo "$BUILD_SETTINGS" | grep WRAPPER_NAME | sed 's/.*= //' | xargs)"
APP_PATH="$TARGET_BUILD_DIR/$WRAPPER_NAME"

if [[ ! -d "$APP_PATH" ]]; then
    echo "❌ Build artifact not found at $APP_PATH"
    exit 1
fi

# 6. Install and Launch
echo "🚀 Installing to $DEVICE_TYPE..."

if [[ "$DEVICE_TYPE" == "physical" ]]; then
    xcrun devicectl device install app --device "$DESTINATION_ID" "$APP_PATH"
    xcrun devicectl device process launch --device "$DESTINATION_ID" "$BUNDLE_ID"
else
    xcrun simctl install "$DESTINATION_ID" "$APP_PATH"
    xcrun simctl launch "$DESTINATION_ID" "$BUNDLE_ID"
fi

echo "✅ App deployed successfully!"