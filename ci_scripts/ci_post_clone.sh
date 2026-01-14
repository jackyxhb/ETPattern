#!/bin/sh

#  ci_post_clone.sh
#  ETPattern
#
#  Created by Agent on 2026-01-11.
#

echo "Stage: Post-clone is executed"

# Example of installing dependencies if needed in the future
# brew install cocoapods
# pod install

echo "Environment check:"
echo "CI_PULL_REQUEST: $CI_PULL_REQUEST"
echo "CI_BRANCH: $CI_BRANCH"
echo "CI_BUILD_ID: $CI_BUILD_ID"
echo "CI_TAG: $CI_TAG"

if [[ -n "$CI_TAG" ]]; then
    echo "🔖 Tag detected: $CI_TAG"
    # Strip 'v' prefix if present
    APP_VERSION="${CI_TAG#v}"
    echo "📲 Setting MARKETING_VERSION to $APP_VERSION"

    # Navigate to project root (already there in post-clone, but being safe)
    # Update MARKETING_VERSION in project.pbxproj
    sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = $APP_VERSION;/g" ETPattern.xcodeproj/project.pbxproj
    
    echo "✅ Updated project version."
else
    echo "ℹ️ No tag detected. Skipping version update."
fi

# Always update build number from CI_BUILD_ID
if [[ -n "$CI_BUILD_ID" ]]; then
    echo "🔢 Setting CURRENT_PROJECT_VERSION to $CI_BUILD_ID"
    sed -i '' "s/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $CI_BUILD_ID;/g" ETPattern.xcodeproj/project.pbxproj
    echo "✅ Updated build number."
else
    echo "ℹ️ No CI_BUILD_ID detected. Keeping existing build number."
fi

exit 0
