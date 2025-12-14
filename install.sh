#!/bin/bash

# ETPattern Install Script
# Device Priority Policy:
# 1. Jack-iPhone16Plus (00008140-000654E61107001C) if connected
# 2. Any other connected iPhone device
# 3. iPhone 16 Simulator (18.6) (0B067B2D-FE51-486D-8EBB-D71DB5D757BD)

echo "Checking for connected devices..."

# Get device list
DEVICE_LIST=$(xcrun xctrace list devices)

# Priority 1: Check for preferred device
PREFERRED_DEVICE_ID="00008140-000654E61107001C"
if echo "$DEVICE_LIST" | grep -q "$PREFERRED_DEVICE_ID"; then
    echo "Found preferred device Jack-iPhone16Plus - installing to physical device..."
    DESTINATION="platform=iOS,id=$PREFERRED_DEVICE_ID"
    DEVICE_TYPE="physical"
else
    echo "Preferred device not found, checking for other connected iPhone devices..."
    
    # Priority 2: Look for any other connected iPhone device (not iPad)
    CONNECTED_IPHONE=$(echo "$DEVICE_LIST" | grep "iPhone" | grep -v "Simulator" | grep -v "Offline" | head -1)
    
    if [ ! -z "$CONNECTED_IPHONE" ]; then
        # Extract device ID from the line like: "Device Name (OS) (ID)"
        DEVICE_ID=$(echo "$CONNECTED_IPHONE" | sed 's/.*(\([^)]*\))$/\1/')
        DEVICE_NAME=$(echo "$CONNECTED_IPHONE" | sed 's/ (.*//')
        echo "Found alternative iPhone device: $DEVICE_NAME - installing to physical device..."
        DESTINATION="platform=iOS,id=$DEVICE_ID"
        DEVICE_TYPE="physical"
    else
        echo "No connected iPhone devices found - using iPhone 16 Simulator (18.6)..."
        DESTINATION="platform=iOS Simulator,id=0B067B2D-FE51-486D-8EBB-D71DB5D757BD"
        DEVICE_TYPE="simulator"
    fi
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
        fi
    else
        echo "Installation failed!"
        exit 1
    fi
else
    echo "Build failed!"
    exit 1
fi