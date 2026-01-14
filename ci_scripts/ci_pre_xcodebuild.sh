#!/bin/bash

#  ci_pre_xcodebuild.sh
#  ETPattern
#
#  Runs just before xcodebuild to set version and build number

set -e  # Exit on error

echo "======================================"
echo "Stage: Pre-xcodebuild is executing"
echo "======================================"

echo "📂 Current directory: $(pwd)"
echo "📁 Project directory contents:"
ls -la

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
        echo "⚠️ No tag found."
        APP_VERSION=""
    fi
fi

# Set Marketing Version using agvtool
if [[ -n "$APP_VERSION" ]]; then
    echo "📲 Setting MARKETING_VERSION to $APP_VERSION using agvtool"
    cd ETPattern.xcodeproj/..
    xcrun agvtool new-marketing-version "$APP_VERSION"
    echo "✅ Marketing version set to $APP_VERSION"
fi

# Set Build Number using agvtool
if [[ -n "$CI_BUILD_ID" ]]; then
    echo "🔢 Setting build number to $CI_BUILD_ID using agvtool"
    xcrun agvtool new-version -all "$CI_BUILD_ID"
    echo "✅ Build number set to $CI_BUILD_ID"
fi

echo "======================================"
echo "📋 Final version check:"
xcrun agvtool what-marketing-version
xcrun agvtool what-version
echo "======================================"

exit 0
