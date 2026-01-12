#!/bin/bash

# This script is intended to be run as a Run Script Build Phase in Xcode.
# It syncs the Info.plist version with the latest git tag.
# It is designed to maximize reliability and NOT fail the build if something goes wrong.

echo "📣 Starting Version Sync Script..."

# Ensure we don't fail the build on intermediate errors
set +e

# Function to handle errors without failing the build
log_warning() {
    echo "warning: [VersionSync] $1"
}

if [ ! -d ".git" ]; then
    log_warning "Not a git repository (or .git directory missing). Skipping version sync."
    exit 0
fi

# Try to get the git tag
GIT_TAG=$(git describe --tags --always --abbrev=0 2>/dev/null)

if [ -z "$GIT_TAG" ]; then
    log_warning "No git tags found or git describe failed. Skipping."
    exit 0
fi

# Strip the leading 'v' if present
VERSION=${GIT_TAG#v}
echo "ℹ️  Detected version from git: $VERSION"

# Locate the Info.plist in the build product
# TARGET_BUILD_DIR and INFOPLIST_PATH are provided by Xcode
TARGET_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [ -z "$TARGET_PLIST" ]; then
   log_warning "TARGET_PLIST path is empty. Xcode environment variables missing?"
   exit 0
fi

if [ ! -f "$TARGET_PLIST" ]; then
    log_warning "Info.plist not found at: $TARGET_PLIST"
    exit 0
fi

echo "ℹ️  Updating $TARGET_PLIST with version $VERSION"

# Use PlistBuddy to set the version
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$TARGET_PLIST"

if [ $? -eq 0 ]; then
    echo "✅ Successfully updated CFBundleShortVersionString to $VERSION"
else
    log_warning "PlistBuddy failed to update version. Continuing build anyway."
fi

# Always exit 0 to ensure we don't break the build
exit 0
