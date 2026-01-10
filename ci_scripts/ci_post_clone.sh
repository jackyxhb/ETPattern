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

exit 0
