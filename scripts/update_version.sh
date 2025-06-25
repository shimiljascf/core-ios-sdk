#!/bin/bash

# Script to update version across all podspec files and create a GitHub release
# Usage: ./scripts/update_version.sh [NEW_VERSION]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to get current version from CashfreePG.podspec
get_current_version() {
    grep -E "s\.version\s*=" "$PROJECT_ROOT/CashfreePG.podspec" | sed -E 's/.*"([^"]+)".*/\1/'
}

# Function to update version in podspec files
update_podspec_version() {
    local new_version=$1
    local podspec_files=(
        "CashfreePG.podspec"
        "CashfreePGCoreSDK.podspec"
        "CashfreePGUISDK.podspec"
        "CashfreeAnalyticsSDK.podspec"
        "CFNetworkSDK.podspec"
    )
    
    for podspec in "${podspec_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$podspec" ]]; then
            print_status "Updating version in $podspec to $new_version"
            sed -i '' "s/s\.version.*=.*/s.version\t\t= \"$new_version\"/" "$PROJECT_ROOT/$podspec"
        else
            print_warning "$podspec not found, skipping..."
        fi
    done
}

# Function to create git tag and push
create_git_tag() {
    local version=$1
    local tag_name="v$version"
    
    print_status "Creating git tag: $tag_name"
    
    # Check if tag already exists
    if git tag -l | grep -q "^$tag_name$"; then
        print_error "Tag $tag_name already exists!"
        read -p "Do you want to delete the existing tag and create a new one? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "$tag_name"
            git push origin ":refs/tags/$tag_name" || true
        else
            print_error "Aborting..."
            exit 1
        fi
    fi
    
    # Stage all changes
    git add .
    
    # Commit changes
    git commit -m "Release version $version

- Updated all podspec files to version $version
- Updated SPM Package.swift configuration
- Ready for GitHub release" || print_warning "No changes to commit"
    
    # Create and push tag
    git tag -a "$tag_name" -m "Release version $version"
    git push origin main
    git push origin "$tag_name"
    
    print_success "Git tag $tag_name created and pushed!"
}

# Function to generate release notes
generate_release_notes() {
    local version=$1
    local previous_version=$2
    
    cat > "$PROJECT_ROOT/RELEASE_NOTES_$version.md" << EOF
# Release Notes - Version $version

## 🚀 What's New

### Swift Package Manager Support
- ✅ Full SPM support with proper dependency management
- ✅ Binary framework distribution via GitHub releases
- ✅ Easy integration with Xcode Package Manager

### Frameworks Included
- **CashfreePG**: Main payment gateway SDK
- **CashfreePGCoreSDK**: Core payment processing functionality
- **CashfreePGUISDK**: UI components for payment flows
- **CashfreeAnalyticsSDK**: Analytics and tracking
- **CFNetworkSDK**: Networking layer

## 📦 Installation

### Swift Package Manager
\`\`\`swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/core-ios-sdk.git", from: "$version")
]
\`\`\`

### CocoaPods
\`\`\`ruby
pod 'CashfreePG', '~> $version'
\`\`\`

## 🔧 Technical Details
- **iOS Deployment Target**: iOS 12.0+
- **Swift Version**: Swift 5.7+
- **Xcode Version**: Xcode 14.0+

## 📱 Platform Support
- iOS arm64 (Device)
- iOS arm64 + x86_64 (Simulator)

## 🆕 Changes from $previous_version
- Added comprehensive SPM support
- Updated package manifest with proper binary targets
- Enhanced documentation and integration guides
- Improved GitHub Actions for automated releases

## 📚 Documentation
- [SPM Integration Guide](SPM_INTEGRATION_GUIDE.md)
- [README](README.md)
- [Sample Applications](Swift+Sample+Application/)

---
For more information, visit our [documentation](https://docs.cashfree.com/docs/ios) or [contact support](mailto:developers@cashfree.com).
EOF

    print_success "Release notes generated: RELEASE_NOTES_$version.md"
}

# Function to validate git repository
validate_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "This is not a git repository!"
        exit 1
    fi
    
    if [[ $(git status --porcelain) ]]; then
        print_warning "You have uncommitted changes. The script will commit all changes."
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Aborting..."
            exit 1
        fi
    fi
}

# Main function
main() {
    local new_version=$1
    
    print_status "Starting version update process..."
    
    # Get current version
    local current_version=$(get_current_version)
    print_status "Current version: $current_version"
    
    # If no version provided, ask for it
    if [[ -z "$new_version" ]]; then
        read -p "Enter new version (current: $current_version): " new_version
        if [[ -z "$new_version" ]]; then
            print_error "Version cannot be empty!"
            exit 1
        fi
    fi
    
    # Validate version format (semantic versioning)
    if [[ ! $new_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format! Please use semantic versioning (e.g., 2.2.5)"
        exit 1
    fi
    
    print_status "New version: $new_version"
    
    # Validate git repository
    validate_git_repo
    
    # Confirm the action
    echo
    print_warning "This will:"
    echo "  1. Update version in all podspec files from $current_version to $new_version"
    echo "  2. Commit all changes to git"
    echo "  3. Create and push git tag v$new_version"
    echo "  4. Generate release notes"
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Aborting..."
        exit 1
    fi
    
    # Update versions
    update_podspec_version "$new_version"
    
    # Generate release notes
    generate_release_notes "$new_version" "$current_version"
    
    # Create git tag and push
    create_git_tag "$new_version"
    
    print_success "Version update completed successfully!"
    echo
    print_status "Next steps:"
    echo "  1. Go to your GitHub repository"
    echo "  2. Navigate to the 'Releases' section"
    echo "  3. Create a new release using tag v$new_version"
    echo "  4. Upload the .xcframework.zip files as release assets"
    echo "  5. Use the generated release notes in RELEASE_NOTES_$new_version.md"
    echo
    print_status "GitHub Release URL: https://github.com/YOUR_USERNAME/core-ios-sdk/releases/new?tag=v$new_version"
}

# Check if help was requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [VERSION]"
    echo
    echo "Updates version across all podspec files and creates a GitHub release tag."
    echo
    echo "Arguments:"
    echo "  VERSION    New version number (e.g., 2.2.5). If not provided, you'll be prompted."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo
    echo "Examples:"
    echo "  $0 2.2.5      # Update to version 2.2.5"
    echo "  $0            # Interactive mode - will prompt for version"
    exit 0
fi

# Run main function
main "$1"
