#!/bin/bash

#  ci_pre_xcodebuild.sh
#  ETPattern
#
#  Sets Marketing Version from Git tag using agvtool.
#  Build number is automatic via $(CI_BUILD_NUMBER) in project settings.

set -e  # Exit on error

echo "======================================"
echo "Stage: Pre-xcodebuild - Version Sync"
echo "======================================"

# Get version from CI_TAG or git describe
if [[ -n "$CI_TAG" ]]; then
    echo "🔖 Tag detected from CI_TAG: $CI_TAG"
    APP_VERSION="${CI_TAG#v}"
else
    echo "ℹ️ CI_TAG not set. Fetching tags from remote..."
    git fetch --tags --quiet 2>/dev/null || true
    GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [[ -n "$GIT_TAG" ]]; then
        echo "🔖 Tag detected from git describe: $GIT_TAG"
        APP_VERSION="${GIT_TAG#v}"
    else
        echo "⚠️ No tag found. Skipping version update."
        APP_VERSION=""
    fi
fi

# Set Marketing Version using agvtool
if [[ -n "$APP_VERSION" ]]; then
    echo "📲 Setting MARKETING_VERSION to $APP_VERSION"
    
    # Navigate to repository root (script runs in ci_scripts directory)
    cd "$CI_PRIMARY_REPOSITORY_PATH" || cd ..
    echo "📂 Working directory: $(pwd)"
    
    # Use agvtool to set marketing version
    xcrun agvtool new-marketing-version "$APP_VERSION"
    
    echo "✅ Marketing version set to $APP_VERSION"
    echo ""
    echo "📋 Version verification:"
    xcrun agvtool what-marketing-version
fi

echo "======================================"
echo "ℹ️ Build number is set automatically via \$(CI_BUILD_NUMBER) in project settings"
echo "======================================"

exit 0
