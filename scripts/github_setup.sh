#!/bin/bash

# Comprehensive GitHub Setup and Release Script
# This script will help you set up your repository on GitHub and create releases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

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

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to check if git is initialized
check_git_init() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_status "Initializing git repository..."
        git init
        print_success "Git repository initialized"
    else
        print_success "Git repository already exists"
    fi
}

# Function to set up .gitignore
setup_gitignore() {
    if [[ ! -f "$PROJECT_ROOT/.gitignore" ]]; then
        print_status "Creating .gitignore file..."
        cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
# Xcode
.DS_Store
.build/
build/
DerivedData/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.xccheckout
*.moved-aside
*.xcuserstate
*.xcscmblueprint
*.xcscheme

# CocoaPods
Pods/
Podfile.lock

# Swift Package Manager
.swiftpm/
.build/
Package.resolved

# Fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
iOSInjectionProject/

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# Release notes
RELEASE_NOTES_*.md

# Logs
*.log
EOF
        print_success ".gitignore created"
    else
        print_success ".gitignore already exists"
    fi
}

# Function to get current version
get_current_version() {
    grep -E "s\.version\s*=" "$PROJECT_ROOT/CashfreePG.podspec" | sed -E 's/.*"([^"]+)".*/\1/'
}

# Function to validate GitHub CLI
check_github_cli() {
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            print_success "GitHub CLI is installed and authenticated"
            return 0
        else
            print_warning "GitHub CLI is installed but not authenticated"
            print_status "Please run: gh auth login"
            return 1
        fi
    else
        print_warning "GitHub CLI is not installed"
        print_status "Install with: brew install gh"
        return 1
    fi
}

# Function to create GitHub repository
create_github_repo() {
    local repo_name="$1"
    local description="$2"
    local is_private="$3"
    
    print_status "Creating GitHub repository: $repo_name"
    
    local visibility_flag=""
    if [[ "$is_private" == "true" ]]; then
        visibility_flag="--private"
    else
        visibility_flag="--public"
    fi
    
    if gh repo create "$repo_name" $visibility_flag --description "$description" --clone=false; then
        print_success "GitHub repository created: https://github.com/$(gh api user --jq .login)/$repo_name"
        return 0
    else
        print_error "Failed to create GitHub repository"
        return 1
    fi
}

# Function to add remote origin
add_remote_origin() {
    local repo_name="$1"
    local username=$(gh api user --jq .login 2>/dev/null || echo "YOUR_USERNAME")
    
    if git remote get-url origin &> /dev/null; then
        print_warning "Remote origin already exists"
        print_status "Current origin: $(git remote get-url origin)"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git remote set-url origin "https://github.com/$username/$repo_name.git"
            print_success "Remote origin updated"
        fi
    else
        git remote add origin "https://github.com/$username/$repo_name.git"
        print_success "Remote origin added: https://github.com/$username/$repo_name.git"
    fi
}

# Function to prepare Package.swift for GitHub releases
prepare_package_swift_for_github() {
    local repo_name="$1"
    local username=$(gh api user --jq .login 2>/dev/null || echo "YOUR_USERNAME")
    
    print_status "Updating Package.swift to use GitHub release URLs..."
    
    # Calculate checksums for existing frameworks
    local checksums=""
    frameworks=("CFNetworkSDK" "CashfreeAnalyticsSDK" "CashfreePGCoreSDK" "CashfreePGUISDK" "CashfreePG")
    
    for framework in "${frameworks[@]}"; do
        if [[ -f "$PROJECT_ROOT/${framework}.xcframework.zip" ]]; then
            local checksum=$(swift package compute-checksum "${framework}.xcframework.zip")
            checksums="${checksums}${framework}=${checksum},"
            print_status "Checksum for ${framework}: $checksum"
        fi
    done
    
    # Create GitHub-ready Package.swift template
    cat > "$PROJECT_ROOT/Package.swift.github" << EOF
// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CashfreePG",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "CashfreePG", targets: ["CashfreePG"]),
        .library(name: "CashfreePGCoreSDK", targets: ["CashfreePGCoreSDK"]),
        .library(name: "CashfreePGUISDK", targets: ["CashfreePGUISDK"]),
        .library(name: "CashfreeAnalyticsSDK", targets: ["CashfreeAnalyticsSDK"]),
        .library(name: "CFNetworkSDK", targets: ["CFNetworkSDK"])
    ],
    targets: [
        .binaryTarget(
            name: "CFNetworkSDK",
            url: "https://github.com/$username/$repo_name/releases/download/v{{VERSION}}/CFNetworkSDK.xcframework.zip",
            checksum: "{{CFNETWORK_CHECKSUM}}"
        ),
        .binaryTarget(
            name: "CashfreeAnalyticsSDK",
            url: "https://github.com/$username/$repo_name/releases/download/v{{VERSION}}/CashfreeAnalyticsSDK.xcframework.zip",
            checksum: "{{ANALYTICS_CHECKSUM}}"
        ),
        .binaryTarget(
            name: "CashfreePGCoreSDK",
            url: "https://github.com/$username/$repo_name/releases/download/v{{VERSION}}/CashfreePGCoreSDK.xcframework.zip",
            checksum: "{{CORE_CHECKSUM}}"
        ),
        .binaryTarget(
            name: "CashfreePGUISDK",
            url: "https://github.com/$username/$repo_name/releases/download/v{{VERSION}}/CashfreePGUISDK.xcframework.zip",
            checksum: "{{UI_CHECKSUM}}"
        ),
        .binaryTarget(
            name: "CashfreePG",
            url: "https://github.com/$username/$repo_name/releases/download/v{{VERSION}}/CashfreePG.xcframework.zip",
            checksum: "{{MAIN_CHECKSUM}}"
        )
    ]
)
EOF
    
    print_success "GitHub Package.swift template created"
}

# Function to commit and push initial version
initial_commit_and_push() {
    print_status "Making initial commit..."
    
    # Stage all files
    git add .
    
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        print_warning "No changes to commit"
    else
        # Commit changes
        local current_version=$(get_current_version)
        git commit -m "Initial commit - Cashfree iOS SDK v$current_version

- Added Swift Package Manager support
- Added CocoaPods support  
- Added sample applications
- Added comprehensive documentation
- Added GitHub Actions for automated releases"
        
        print_success "Initial commit created"
    fi
    
    # Push to GitHub
    print_status "Pushing to GitHub..."
    if git push -u origin main; then
        print_success "Code pushed to GitHub successfully!"
    else
        print_error "Failed to push to GitHub"
        return 1
    fi
}

# Function to create first release
create_first_release() {
    local version="$1"
    local repo_name="$2"
    
    print_status "Creating first release: v$version"
    
    # Create and push tag
    git tag -a "v$version" -m "Release version $version"
    git push origin "v$version"
    
    # Create release using GitHub CLI
    local release_notes="# 🚀 Cashfree Payment Gateway iOS SDK v$version

## What's New

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
    .package(url: \"https://github.com/$(gh api user --jq .login)/$repo_name.git\", from: \"$version\")
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

---
For more information, visit our [documentation](https://docs.cashfree.com/docs/ios)"

    # Create release with framework assets
    if gh release create "v$version" \
        --title "Cashfree iOS SDK v$version" \
        --notes "$release_notes" \
        CashfreePG.xcframework.zip \
        CashfreePGCoreSDK.xcframework.zip \
        CashfreePGUISDK.xcframework.zip \
        CashfreeAnalyticsSDK.xcframework.zip \
        CFNetworkSDK.xcframework.zip; then
        print_success "Release v$version created successfully!"
        return 0
    else
        print_error "Failed to create release"
        return 1
    fi
}

# Main setup function
main() {
    print_header "GitHub Setup and Release Script"
    
    cd "$PROJECT_ROOT"
    
    # Get current version
    local current_version=$(get_current_version)
    print_status "Current SDK version: $current_version"
    
    # Check if GitHub CLI is available
    if ! check_github_cli; then
        print_error "GitHub CLI is required for this script"
        echo "Please install and authenticate GitHub CLI:"
        echo "  brew install gh"
        echo "  gh auth login"
        exit 1
    fi
    
    # Get repository details
    echo
    print_status "Repository Setup"
    read -p "Enter repository name (e.g., cashfree-ios-sdk): " repo_name
    read -p "Enter repository description: " repo_description
    read -p "Make repository private? (y/N): " -n 1 -r
    echo
    local is_private="false"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        is_private="true"
    fi
    
    # Setup git
    check_git_init
    setup_gitignore
    
    # Create GitHub repository
    if ! create_github_repo "$repo_name" "$repo_description" "$is_private"; then
        print_error "Failed to create GitHub repository"
        exit 1
    fi
    
    # Add remote origin
    add_remote_origin "$repo_name"
    
    # Prepare Package.swift for GitHub
    prepare_package_swift_for_github "$repo_name"
    
    # Initial commit and push
    if ! initial_commit_and_push; then
        print_error "Failed to push initial commit"
        exit 1
    fi
    
    # Ask about creating first release
    echo
    read -p "Do you want to create the first release (v$current_version) now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if create_first_release "$current_version" "$repo_name"; then
            echo
            print_success "🎉 Setup completed successfully!"
            echo
            print_status "Your repository is ready:"
            echo "  🔗 Repository: https://github.com/$(gh api user --jq .login)/$repo_name"
            echo "  🏷️  Release: https://github.com/$(gh api user --jq .login)/$repo_name/releases/tag/v$current_version"
            echo "  📦 SPM URL: https://github.com/$(gh api user --jq .login)/$repo_name.git"
            echo
            print_status "Next steps:"
            echo "  1. Update your README.md with the correct repository URLs"
            echo "  2. Test SPM integration in a sample project"
            echo "  3. Share your SDK with the community!"
        fi
    else
        print_success "Repository setup completed!"
        echo
        print_status "To create a release later, use:"
        echo "  ./scripts/update_version.sh $current_version"
    fi
}

# Show help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "GitHub Setup and Release Script"
    echo
    echo "This script will:"
    echo "  1. Initialize git repository (if needed)"
    echo "  2. Create .gitignore file"
    echo "  3. Create GitHub repository"
    echo "  4. Add remote origin"
    echo "  5. Make initial commit and push"
    echo "  6. Create first release with framework assets"
    echo
    echo "Requirements:"
    echo "  - GitHub CLI (gh) installed and authenticated"
    echo "  - XCFramework zip files present in project root"
    echo
    echo "Usage: $0"
    exit 0
fi

# Run main function
main
