#!/bin/bash

# Release script for Cashfree iOS SDK
# This script helps create and publish new releases with proper versioning

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if version is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <version>"
    print_error "Example: $0 2.2.5"
    exit 1
fi

NEW_VERSION=$1
CURRENT_DIR=$(pwd)

print_status "Starting release process for version $NEW_VERSION"

# Validate version format
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Please use semantic versioning (e.g., 2.2.5)"
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found. Please run this script from the repository root."
    exit 1
fi

# Check if git is clean
if [ -n "$(git status --porcelain)" ]; then
    print_error "Git working directory is not clean. Please commit or stash changes first."
    git status --short
    exit 1
fi

# Check if we're on main/master branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    print_warning "You're not on main/master branch. Current branch: $CURRENT_BRANCH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "Updating version in podspec files..."

# Update version in podspec files
PODSPECS=("CashfreePG.podspec" "CashfreePGCoreSDK.podspec" "CashfreePGUISDK.podspec")

for podspec in "${PODSPECS[@]}"; do
    if [ -f "$podspec" ]; then
        print_status "Updating $podspec"
        sed -i.bak "s/s\.version[[:space:]]*=[[:space:]]*\"[0-9]*\.[0-9]*\.[0-9]*\"/s.version = \"$NEW_VERSION\"/" "$podspec"
        rm "$podspec.bak"
        
        # Update dependencies to use new version
        sed -i.bak "s/'CashfreePG[A-Za-z]*', '[0-9]*\.[0-9]*\.[0-9]*'/'CashfreePG', '$NEW_VERSION'/" "$podspec"
        sed -i.bak "s/'CashfreePGCoreSDK', '[0-9]*\.[0-9]*\.[0-9]*'/'CashfreePGCoreSDK', '$NEW_VERSION'/" "$podspec"
        sed -i.bak "s/'CashfreePGUISDK', '[0-9]*\.[0-9]*\.[0-9]*'/'CashfreePGUISDK', '$NEW_VERSION'/" "$podspec"
        rm -f "$podspec.bak"
    fi
done

print_status "Validating Swift Package..."

# Validate Swift Package
if ! swift package resolve; then
    print_error "Swift package resolution failed"
    exit 1
fi

if ! swift package dump-package > /dev/null; then
    print_error "Swift package validation failed"
    exit 1
fi

print_status "Validating XCFrameworks..."

# Check if all required XCFrameworks exist
FRAMEWORKS=("CashfreePG" "CashfreePGCoreSDK" "CashfreePGUISDK" "CashfreeAnalyticsSDK" "CFNetworkSDK")

for framework in "${FRAMEWORKS[@]}"; do
    if [ ! -d "${framework}.xcframework" ]; then
        print_error "${framework}.xcframework not found"
        exit 1
    fi
    
    # Check for required architectures
    if [ ! -d "${framework}.xcframework/ios-arm64" ]; then
        print_error "${framework}.xcframework missing ios-arm64 architecture"
        exit 1
    fi
    
    if [ ! -d "${framework}.xcframework/ios-arm64_x86_64-simulator" ]; then
        print_error "${framework}.xcframework missing simulator architecture"
        exit 1
    fi
done

print_status "All validations passed!"

# Create ZIP files for release
print_status "Creating ZIP archives..."

for framework in "${FRAMEWORKS[@]}"; do
    if [ -f "${framework}.xcframework.zip" ]; then
        rm "${framework}.xcframework.zip"
    fi
    zip -r "${framework}.xcframework.zip" "${framework}.xcframework" > /dev/null
    print_status "Created ${framework}.xcframework.zip"
done

# Commit changes
print_status "Committing version bump..."
git add .
git commit -m "Bump version to $NEW_VERSION"

# Create and push tag
print_status "Creating and pushing tag..."
git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"
git push origin "v$NEW_VERSION"
git push origin "$CURRENT_BRANCH"

print_status "Release $NEW_VERSION completed successfully!"
print_status "GitHub Actions will automatically create the release and validate the package."

# Instructions for manual steps
echo
print_status "Next steps:"
echo "1. Monitor GitHub Actions for release validation"
echo "2. Update CocoaPods specs if needed:"
echo "   pod trunk push CashfreePG.podspec"
echo "3. Update documentation if needed"
echo "4. Announce the release"

print_status "Release process completed!"
