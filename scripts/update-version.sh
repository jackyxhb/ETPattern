#!/bin/bash

# Script to update MARKETING_VERSION in project.pbxproj from the latest git tag
# Usage: ./scripts/update-version.sh [version]
#   - If version is provided, uses that version
#   - If no version is provided, uses the latest git tag

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_FILE="$PROJECT_ROOT/ETPattern.xcodeproj/project.pbxproj"

# Get version from argument or latest tag
if [ -n "$1" ]; then
    VERSION="$1"
else
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
fi

if [ -z "$VERSION" ]; then
    echo "❌ Error: No version provided and no git tags found."
    echo "Usage: $0 [version]"
    exit 1
fi

echo "📦 Updating MARKETING_VERSION to $VERSION..."

# Update MARKETING_VERSION in project.pbxproj
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/g" "$PROJECT_FILE"

# Verify the change
UPDATED=$(grep -c "MARKETING_VERSION = $VERSION;" "$PROJECT_FILE" || true)

if [ "$UPDATED" -gt 0 ]; then
    echo "✅ Successfully updated MARKETING_VERSION to $VERSION ($UPDATED occurrences)"
    echo ""
    echo "Next steps:"
    echo "  1. git add ETPattern.xcodeproj/project.pbxproj"
    echo "  2. git commit -m 'Bump version to $VERSION'"
    echo "  3. git tag v$VERSION (if not already tagged)"
else
    echo "❌ Failed to update MARKETING_VERSION"
    exit 1
fi
