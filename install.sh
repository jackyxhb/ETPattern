#!/usr/bin/env bash

set -euo pipefail

# ETPattern Install Script
# Device Selection Policy:
# 1) Before build/install, list all devices.
# 2) Pick the first connected iPhone device (not simulator, not offline).
# 3) If none, pick the first BOOTED iPhone simulator.
# 4) If none, boot an iPhone 16 simulator (first match) and use it.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$ROOT_DIR/ETPattern.xcodeproj"
SCHEME="ETPattern"
BUNDLE_ID="com.jack.ETPattern"

echo "Listing devices (devicectl):"
xcrun devicectl list devices || true

echo "Selecting destination..."

DEVICE_LIST="$(xcrun devicectl list devices)"

# Extract connected physical iPhone identifiers (exclude simulators).
CONNECTED_IPHONE_IDS="$(echo "$DEVICE_LIST" | grep "iPhone" | grep "connected" | awk '{print $3}' || echo "")"

DEVICE_TYPE=""
DESTINATION=""
DESTINATION_ID=""
SDK=""

# Check for USB-connected physical iPhone.
for ID in $CONNECTED_IPHONE_IDS; do
    INFO="$(xcrun devicectl device info details --device "$ID")"
    TRANSPORT_TYPE="$(echo "$INFO" | grep "transportType" | awk '{print $2}')"
    if [[ "$TRANSPORT_TYPE" == "usb" ]]; then
        DESTINATION_ID="$ID"
        DEVICE_NAME="$(echo "$DEVICE_LIST" | grep "$ID" | awk '{print $1}')"
        DEVICE_TYPE="physical"
        DESTINATION="platform=iOS,id=$DESTINATION_ID"
        SDK="iphoneos"
        echo "Selected USB-connected physical device: $DEVICE_NAME ($DESTINATION_ID)"
        break
    fi
done

if [[ -z "$DESTINATION_ID" ]]; then
    # Find a booted iPhone simulator.
    BOOTED_SIM_LINE="$(xcrun simctl list devices booted | grep "iPhone" | head -n 1 || true)"
    if [[ -n "$BOOTED_SIM_LINE" ]]; then
        DESTINATION_ID="$(echo "$BOOTED_SIM_LINE" | sed -n 's/.*(\([0-9A-F-]*\)).*/\1/p')"
        DEVICE_TYPE="simulator"
        DESTINATION="platform=iOS Simulator,id=$DESTINATION_ID"
        SDK="iphonesimulator"
        echo "Selected booted simulator: $BOOTED_SIM_LINE"
    else
        # No booted iPhone simulators: boot an iPhone 16 simulator (first match).
        IPHONE16_LINE="$(xcrun simctl list devices available | grep "iPhone 16" | head -n 1 || true)"
        if [[ -z "$IPHONE16_LINE" ]]; then
            echo "ERROR: No available 'iPhone 16' simulator found. Open Xcode > Settings > Platforms to install iOS simulators."
            exit 1
        fi

        DESTINATION_ID="$(echo "$IPHONE16_LINE" | sed -n 's/.*(\([0-9A-F-]*\)).*/\1/p')"
        echo "Booting simulator: $IPHONE16_LINE"
        xcrun simctl boot "$DESTINATION_ID" || true
        xcrun simctl bootstatus "$DESTINATION_ID" -b

        DEVICE_TYPE="simulator"
        DESTINATION="platform=iOS Simulator,id=$DESTINATION_ID"
        SDK="iphonesimulator"
    fi
fi

cd "$ROOT_DIR"

echo "Building ($SDK) for destination: $DESTINATION"
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -sdk "$SDK" \
    -configuration Debug \
    -destination "$DESTINATION" \
    build

echo "Resolving built app path from xcodebuild settings..."
BUILD_SETTINGS="$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -sdk "$SDK" -configuration Debug -destination "$DESTINATION" -showBuildSettings)"
TARGET_BUILD_DIR="$(echo "$BUILD_SETTINGS" | grep TARGET_BUILD_DIR | sed 's/.*= //' | xargs)"
WRAPPER_NAME="$(echo "$BUILD_SETTINGS" | grep WRAPPER_NAME | sed 's/.*= //' | xargs)"
APP_PATH="$TARGET_BUILD_DIR/$WRAPPER_NAME"

if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: Built app not found at: $APP_PATH"
    exit 1
fi

echo "Installing: $APP_PATH"

if [[ "$DEVICE_TYPE" == "physical" ]]; then
    xcrun devicectl device install app --device "$DESTINATION_ID" "$APP_PATH"
    echo "Launching on device..."
    xcrun devicectl device process launch --device "$DESTINATION_ID" "$BUNDLE_ID" || true
else
    xcrun simctl install "$DESTINATION_ID" "$APP_PATH"
    echo "Launching on simulator..."
    xcrun simctl launch "$DESTINATION_ID" "$BUNDLE_ID" || true
fi

echo "Done."