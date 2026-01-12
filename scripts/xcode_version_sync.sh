#!/bin/bash

# This script is intended to be run as a Run Script Build Phase in Xcode.
# It syncs the Info.plist version with the latest git tag.

if [ -d ".git" ]; then
    # Get the latest git tag (e.g., v2.0.4)
    GIT_TAG=$(git describe --tags --always --abbrev=0)
    
    # Strip the leading 'v' if present
    VERSION=${GIT_TAG#v}
    
    echo "Syncing version to $VERSION from git tag $GIT_TAG"
    
    # Update the built Info.plist directly in the build product
    # This ensures the running app has the correct version without modifying the source file
    TARGET_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
    
    if [ -f "$TARGET_PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$TARGET_PLIST"
        echo "Updated CFBundleShortVersionString in $TARGET_PLIST"
    else
        echo "Warning: Info.plist not found at $TARGET_PLIST"
    fi
else
    echo "Warning: Not a git repository, skipping version sync."
fi
