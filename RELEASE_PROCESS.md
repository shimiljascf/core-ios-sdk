# Release Process Guide

This document outlines the complete process for releasing the Cashfree iOS SDK to GitHub with Swift Package Manager support.

## 🚀 Quick Release (Existing Repository)

If your repository is already set up on GitHub:

```bash
# Update to new version (e.g., 2.2.5)
./scripts/update_version.sh 2.2.5
```

This script will:
- ✅ Update all podspec files
- ✅ Commit changes to git
- ✅ Create and push git tag
- ✅ Generate release notes
- ✅ Trigger GitHub Actions for automated release

## 🏗️ First Time Setup

If this is your first time pushing to GitHub:

```bash
# Run the interactive setup script
./scripts/github_setup.sh
```

This script will:
- ✅ Initialize git repository
- ✅ Create .gitignore file
- ✅ Create GitHub repository
- ✅ Configure remote origin
- ✅ Make initial commit and push
- ✅ Create first release with framework assets

## 📋 Manual Release Process

If you prefer to do it manually:

### Step 1: Prepare Your Code

1. **Update version numbers** in all podspec files:
   - CashfreePG.podspec
   - CashfreePGCoreSDK.podspec
   - CashfreePGUISDK.podspec
   - CashfreeAnalyticsSDK.podspec
   - CFNetworkSDK.podspec

2. **Verify XCFramework files exist**:
   ```bash
   ls -la *.xcframework.zip
   ```

3. **Test SPM configuration**:
   ```bash
   swift package resolve
   swift build
   ```

### Step 2: Git Operations

1. **Stage and commit changes**:
   ```bash
   git add .
   git commit -m "Release version 2.2.5"
   ```

2. **Create and push tag**:
   ```bash
   git tag -a v2.2.5 -m "Release version 2.2.5"
   git push origin main
   git push origin v2.2.5
   ```

### Step 3: Create GitHub Release

1. **Go to your GitHub repository**
2. **Click "Releases" → "Create a new release"**
3. **Select the tag** you just created (v2.2.5)
4. **Add release title**: "Cashfree iOS SDK v2.2.5"
5. **Add release notes** (use the generated template)
6. **Upload framework assets**:
   - CashfreePG.xcframework.zip
   - CashfreePGCoreSDK.xcframework.zip
   - CashfreePGUISDK.xcframework.zip
   - CashfreeAnalyticsSDK.xcframework.zip
   - CFNetworkSDK.xcframework.zip
7. **Publish release**

## 📦 Package.swift Configuration

For SPM to work with GitHub releases, your Package.swift should reference the release URLs:

```swift
.binaryTarget(
    name: "CashfreePG",
    url: "https://github.com/YOUR_USERNAME/core-ios-sdk/releases/download/v2.2.5/CashfreePG.xcframework.zip",
    checksum: "your_checksum_here"
)
```

### Calculating Checksums

```bash
swift package compute-checksum CashfreePG.xcframework.zip
```

## 🔄 GitHub Actions Automation

The repository includes GitHub Actions that automatically:

1. **Validate SPM configuration** on tag push
2. **Create GitHub release** with proper formatting
3. **Upload framework assets** to the release
4. **Update Package.swift** with release URLs and checksums

### Workflow Triggers

- **Automatic**: When you push a tag starting with 'v' (e.g., v2.2.5)
- **Manual**: Through GitHub Actions web interface

## ✅ Post-Release Checklist

After creating a release:

1. **Test SPM integration** in a sample project:
   ```swift
   .package(url: "https://github.com/YOUR_USERNAME/core-ios-sdk.git", from: "2.2.5")
   ```

2. **Update documentation** if needed
3. **Verify CocoaPods** still works:
   ```bash
   pod lib lint CashfreePG.podspec
   ```

4. **Announce the release** to your users

## 🐛 Troubleshooting

### Common Issues

**SPM can't resolve package:**
- Check if all framework zip files are uploaded to the release
- Verify checksums in Package.swift match the actual files
- Ensure the release is published (not draft)

**GitHub Actions fail:**
- Check if repository secrets are configured
- Verify workflow permissions in repository settings
- Ensure all required files exist in the repository

**CocoaPods integration breaks:**
- Verify podspec syntax: `pod lib lint`
- Check if framework paths are correct
- Ensure all dependencies are properly specified

## 📞 Support

For issues with the release process:
1. Check the [GitHub Actions logs](../../actions)
2. Verify all prerequisites are met
3. Review this guide for missed steps
4. Contact the development team

---

**Pro Tip**: Use the automated scripts whenever possible to reduce human error and ensure consistency across releases.
