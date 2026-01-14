#!/bin/bash

#  ci_pre_xcodebuild.sh
#  ETPattern
#
#  Sets Marketing Version from Git tag by directly editing project.pbxproj.
#  Build number is automatic via $(CI_BUILD_NUMBER) in project settings.

set -e  # Exit on error

echo "======================================"
echo "Stage: Pre-xcodebuild - Version Sync"
echo "======================================"
echo "📂 Script directory: $(pwd)"
echo "🔧 CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"

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

# Set Marketing Version by directly editing project.pbxproj
if [[ -n "$APP_VERSION" ]]; then
    echo "📲 Setting MARKETING_VERSION to $APP_VERSION"
    
    # Navigate to repository root
    cd "$CI_PRIMARY_REPOSITORY_PATH" || cd ..
    echo "📂 Working directory: $(pwd)"
    
    # Show current value
    echo "📋 Current MARKETING_VERSION values:"
    grep "MARKETING_VERSION" ETPattern.xcodeproj/project.pbxproj || echo "  (none found)"
    
    # Update MARKETING_VERSION in project.pbxproj using sed
    sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $APP_VERSION;/g" ETPattern.xcodeproj/project.pbxproj
    
    echo "✅ Updated MARKETING_VERSION"
    echo "📋 New MARKETING_VERSION values:"
    grep "MARKETING_VERSION" ETPattern.xcodeproj/project.pbxproj || echo "  (none found)"
fi

echo "======================================"
echo "ℹ️ Build number is set automatically via \$(CI_BUILD_NUMBER)"
echo "======================================"

exit 0
