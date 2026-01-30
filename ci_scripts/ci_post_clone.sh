#!/bin/bash

#  ci_post_clone.sh
#  ETPattern
#
#  Runs after Xcode Cloud clones the repository.
#  Version sync is now handled by ci_pre_xcodebuild.sh using agvtool.

echo "Stage: Post-clone is executed"

# Example of installing dependencies if needed in the future
# brew install cocoapods
# pod install

echo "Environment check:"
echo "CI_PULL_REQUEST: $CI_PULL_REQUEST"
echo "CI_BRANCH: $CI_BRANCH"
echo "CI_BUILD_ID: $CI_BUILD_ID"
echo "CI_TAG: $CI_TAG"
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"

echo "✅ Post-clone complete. Version sync will run in ci_pre_xcodebuild.sh"

exit 0
