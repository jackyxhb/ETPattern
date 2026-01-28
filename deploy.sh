#!/bin/bash

# Configuration
PROJECT_NAME="ETPattern"
SCHEME_NAME="ETPattern"
# iPhone 16 Plus
DEVICE_ID="00008140-000654E61107001C"
CONFIGURATION="Debug"
BUNDLE_ID="com.jackxhb.ETPattern"

echo "🚀 Starting deployment to device ($DEVICE_ID)..."

# 1. Build the app
echo "📦 Building $SCHEME_NAME..."
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "$SCHEME_NAME" \
           -configuration "$CONFIGURATION" \
           -sdk iphoneos \
           -destination "id=$DEVICE_ID" \
           -derivedDataPath "build" \
           -allowProvisioningUpdates \
           build | xcbeautify || xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" -sdk iphoneos -destination "id=$DEVICE_ID" -derivedDataPath "build" -allowProvisioningUpdates build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# 2. Locate the app bundle
APP_PATH=$(find build -path "*iphoneos*" -name "${PROJECT_NAME}.app" -type d | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Could not find the built app bundle!"
    exit 1
fi

echo "🔍 Found app at: $APP_PATH"

# 3. Install the app to the device
echo "📲 Installing to device..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Successfully installed $SCHEME_NAME to your iPhone!"
    # 4. Launch the app
    echo "▶️ Launching app..."
    xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID"
else
    echo "❌ Installation failed!"
    exit 1
fi
