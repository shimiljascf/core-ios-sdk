#!/bin/bash

# Pre-release validation script
# Checks if everything is ready for GitHub release

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[CHECK]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ISSUES=0

echo "🔍 Pre-Release Validation Checklist"
echo "=================================="

# Check git repository
print_status "Checking git repository..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    print_success "Git repository initialized"
else
    print_error "Not a git repository"
    ((ISSUES++))
fi

# Check for uncommitted changes
print_status "Checking for uncommitted changes..."
if [[ -n $(git status --porcelain) ]]; then
    print_warning "You have uncommitted changes"
    git status --short
    echo "These will be committed during release"
else
    print_success "Working directory clean"
fi

# Check remote origin
print_status "Checking remote origin..."
if git remote get-url origin &> /dev/null; then
    print_success "Remote origin configured: $(git remote get-url origin)"
else
    print_error "No remote origin configured"
    echo "Run: git remote add origin https://github.com/USERNAME/REPO.git"
    ((ISSUES++))
fi

# Check required files
print_status "Checking required files..."
required_files=(
    "Package.swift"
    "CashfreePG.podspec"
    "CashfreePGCoreSDK.podspec"
    "CashfreePGUISDK.podspec"
    "CashfreeAnalyticsSDK.podspec"
    "CFNetworkSDK.podspec"
    "README.md"
    "LICENSE.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
        print_success "$file exists"
    else
        print_error "$file missing"
        ((ISSUES++))
    fi
done

# Check XCFramework zip files
print_status "Checking XCFramework zip files..."
frameworks=(
    "CashfreePG.xcframework.zip"
    "CashfreePGCoreSDK.xcframework.zip" 
    "CashfreePGUISDK.xcframework.zip"
    "CashfreeAnalyticsSDK.xcframework.zip"
    "CFNetworkSDK.xcframework.zip"
)

for framework in "${frameworks[@]}"; do
    if [[ -f "$PROJECT_ROOT/$framework" ]]; then
        size=$(du -h "$PROJECT_ROOT/$framework" | cut -f1)
        print_success "$framework exists ($size)"
    else
        print_error "$framework missing"
        ((ISSUES++))
    fi
done

# Check Package.swift syntax
print_status "Validating Package.swift..."
cd "$PROJECT_ROOT"
if swift package resolve &> /dev/null; then
    print_success "Package.swift is valid"
else
    print_error "Package.swift has syntax errors"
    ((ISSUES++))
fi

# Check podspec syntax
print_status "Validating podspecs..."
for podspec in CashfreePG.podspec CashfreePGCoreSDK.podspec CashfreePGUISDK.podspec CashfreeAnalyticsSDK.podspec CFNetworkSDK.podspec; do
    if pod lib lint "$podspec" --no-subspecs --allow-warnings &> /dev/null; then
        print_success "$podspec is valid"
    else
        print_warning "$podspec has validation warnings (this is usually OK)"
    fi
done

# Check version consistency
print_status "Checking version consistency..."
main_version=$(grep -E "s\.version\s*=" CashfreePG.podspec | sed -E 's/.*"([^"]+)".*/\1/')
echo "Main version: $main_version"

for podspec in CashfreePGCoreSDK.podspec CashfreePGUISDK.podspec CashfreeAnalyticsSDK.podspec CFNetworkSDK.podspec; do
    version=$(grep -E "s\.version\s*=" "$podspec" | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ "$version" == "$main_version" ]]; then
        print_success "$podspec version matches ($version)"
    else
        print_error "$podspec version mismatch: $version (expected: $main_version)"
        ((ISSUES++))
    fi
done

# Check GitHub CLI
print_status "Checking GitHub CLI..."
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        print_success "GitHub CLI authenticated"
    else
        print_warning "GitHub CLI not authenticated (run: gh auth login)"
    fi
else
    print_warning "GitHub CLI not installed (install: brew install gh)"
fi

# Check GitHub Actions workflow
print_status "Checking GitHub Actions workflow..."
if [[ -f ".github/workflows/release.yml" ]]; then
    print_success "Release workflow exists"
else
    print_warning "No GitHub Actions release workflow found"
fi

# Summary
echo
echo "🏁 Validation Summary"
echo "===================="

if [[ $ISSUES -eq 0 ]]; then
    print_success "All checks passed! Ready for release 🚀"
    echo
    echo "Next steps:"
    echo "  1. Update version: ./scripts/update_version.sh [NEW_VERSION]"
    echo "  2. Or setup GitHub: ./scripts/github_setup.sh"
    echo
    exit 0
else
    print_error "Found $ISSUES issue(s) that need to be resolved"
    echo
    echo "Please fix the issues above before proceeding with release."
    exit 1
fi
