#!/bin/bash

# ETPattern Install Script
# Device Selection Policy:
# 1. Find the first available connected iPhone device (not simulator, not offline)
# 2. If no physical iPhone devices found, use iPhone 16 Simulator

echo "Checking for connected devices..."

# Get device list
DEVICE_LIST=$(xcrun xctrace list devices)

# Look for the first available connected iPhone device (not simulator, not offline)
CONNECTED_IPHONE=$(echo "$DEVICE_LIST" | grep "iPhone" | grep -v "Simulator" | grep -v "Offline" | head -1)

if [ ! -z "$CONNECTED_IPHONE" ]; then
    # Extract device ID from the line like: "Device Name (OS) (ID)"
    DEVICE_ID=$(echo "$CONNECTED_IPHONE" | sed 's/.*(\([^)]*\))$/\1/')
    DEVICE_NAME=$(echo "$CONNECTED_IPHONE" | sed 's/ (.*//')
    echo "Found iPhone device: $DEVICE_NAME - installing to physical device..."
    DESTINATION="platform=iOS,id=$DEVICE_ID"
    DEVICE_TYPE="physical"
else
    echo "No connected iPhone devices found - using iPhone 16 Simulator..."
    DESTINATION="platform=iOS Simulator,id=0B067B2D-FE51-486D-8EBB-D71DB5D757BD"
    DEVICE_TYPE="simulator"
fi

echo "Building and installing ETPattern..."

cd /Users/macbook1/work/ETPattern

xcodebuild -project ETPattern.xcodeproj \
           -scheme ETPattern \
           -sdk iphoneos \
           -configuration Debug \
           -destination "$DESTINATION" \
           build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Installing to device..."
    
    if [ "$DEVICE_TYPE" = "physical" ]; then
        # Use devicectl for physical devices
        APP_PATH="/Users/macbook1/Library/Developer/Xcode/DerivedData/ETPattern-ceepkkizhrfttrghnalmrcwlbsmz/Build/Products/Debug-iphoneos/ETPattern.app"
        # Extract device ID from destination
        DEVICE_ID=$(echo "$DESTINATION" | sed 's/platform=iOS,id=//')
        xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
    else
        # Use xcodebuild install for simulator
        xcodebuild -project ETPattern.xcodeproj \
                   -scheme ETPattern \
                   -sdk iphoneos \
                   -configuration Debug \
                   -destination "$DESTINATION" \
                   install
    fi
    
    if [ $? -eq 0 ]; then
        echo "Installation successful!"
        
        if [ "$DEVICE_TYPE" = "simulator" ]; then
            echo "Launching app on simulator..."
            xcrun simctl launch 0B067B2D-FE51-486D-8EBB-D71DB5D757BD aaaa.ETPattern
        else
            echo "Launching app on device..."
            xcrun devicectl device process launch --device "$DEVICE_ID" aaaa.ETPattern
        fi
    else
        echo "Installation failed!"
        exit 1
    fi
else
    echo "Build failed!"
    exit 1
fi