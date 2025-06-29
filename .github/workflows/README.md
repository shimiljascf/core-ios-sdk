# GitHub Actions Workflows for Swift Package

This repository contains GitHub Actions workflows for automatically validating and syncing the CashfreePG iOS SDK to Swift Package Registry.

## 🤖 What the Workflows Do (Automatically)

### 1. Swift Package Registry Sync (`swift-package-release.yml`)

**Trigger:** When a new tag is pushed (e.g., `1.0.11`)

**What it does automatically:**
1. ✅ **Validates Package.swift** - Checks syntax and structure
2. ✅ **Resolves Dependencies** - Ensures all dependencies work
3. ✅ **Builds Package** - Compiles the Swift package successfully
4. ✅ **Runs Tests** - Executes any existing test targets
5. ✅ **Validates XCFrameworks** - Verifies Info.plist and structure
6. ✅ **Publishes to Registry** - Uses GitHub Action to sync to https://swiftpackageregistry.com
7. ✅ **Reports Results** - Shows detailed summary in GitHub Actions

### 2. Swift Package Validation (`swift-package-validation.yml`)

**Trigger:** Pull requests and pushes to main branches

**What it does:**
- Validates Package.swift syntax and structure
- Ensures XCFrameworks are properly configured
- Checks Podspec file syntax
- Provides early feedback on package issues

### 3. Swift Package Delete Helper (`swift-package-delete.yml`)

**Trigger:** Manual workflow dispatch

**What it does:**
- Provides guided deletion instructions
- Validates version format
- Requires explicit confirmation
- Shows manual steps for registry deletion

## 🔐 Authentication & Setup

### **❌ NO SECRET KEY NEEDED!**

Your workflow **requires ZERO authentication** because:

1. **GitHub Action Approach**: `twodayslate/swift-package-registry@v0.0.2`
   - ✅ **No token parameter** required
   - ✅ **Scans public repositories** automatically
   - ✅ **No manual authentication** needed
   - ✅ **Works immediately** without setup

2. **How It Connects:**
   - The action **indexes your public repository**
   - It reads your `Package.swift` file directly
   - It validates your package structure
   - It adds your package to https://swiftpackageregistry.com automatically

3. **Current Implementation:**
   ```yaml
   - name: Publish to Swift Package Registry
     uses: twodayslate/swift-package-registry@v0.0.2
     with:
       source: '.'  # ✅ ONLY SOURCE NEEDED - NO TOKEN
   ```

## � How to Use

### **For Each Release:**

#### Option A: GitHub UI (Recommended) 🖱️
1. Go to your repository → **Releases**
2. Click **"Create a new release"**
3. Choose tag: `1.0.11` (semantic versioning)
4. Add release title: **"CashfreePG 1.0.11"**
5. Write release notes
6. Click **"Publish release"**
7. → Workflow triggers automatically

#### Option B: Command Line 💻
```bash
# Create and push tag
git tag 1.0.11
git push origin 1.0.11

# Workflow runs automatically
# (Optional) Create GitHub release manually later
```

### **Development Validation:**
- Runs automatically on PRs that modify `Package.swift`, XCFrameworks, or Podspecs
- Manual trigger available from GitHub Actions tab

## 🗑️ Package Deletion

### **1. Manual Deletion (Most Common)**

Since Swift Package Registry doesn't provide automated deletion:

#### **Step 1: Request Deletion from Registry**
1. Go to: https://github.com/twodayslate/swift-package-registry/issues
2. Create new issue with:
   - **Title**: "Delete package CashfreePG version X.X.X"
   - **Body**: "Please remove CashfreePG version X.X.X from the registry"

#### **Step 2: Delete Git Tag (Optional)**
```bash
# Delete remote tag
git push --delete origin 1.0.11

# Delete local tag  
git tag -d 1.0.11
```

#### **Step 3: Delete GitHub Release (Optional)**
1. Go to: https://github.com/your-repo/releases
2. Find the release → Delete

### **2. Automated Deletion Helper**

Use the `swift-package-delete.yml` workflow:

#### **How to Use:**
1. Go to **Actions** tab in your repository
2. Click **"Swift Package Registry - Delete Package"**
3. Click **"Run workflow"**
4. Enter:
   - **Version**: `1.0.11` (version to delete)
   - **Confirmation**: `DELETE` (exactly as typed)
5. Click **"Run workflow"**

#### **What It Does:**
- ✅ Validates version format
- ✅ Requires explicit confirmation
- ✅ Provides manual deletion instructions
- ✅ Shows commands to delete git tags/releases
- ❌ **Cannot delete from registry automatically** (not supported)

## 🎯 Trigger Conditions

### ✅ **Will Trigger Registry Sync:**
- `1.0.0`, `1.0.1`, `1.0.11` (semantic versions)
- Manual run from GitHub Actions tab

### ❌ **Will NOT Trigger:**
- `analytics-1.0.11` (component-specific tags)
- `ui-2.0.14` (UI-specific tags)
- `v1.0.11` (v-prefixed tags)
- `1.0.11-beta` (pre-release tags)

## 📦 Package Installation (For Your Users)

After successful workflow execution, users can install via:

### Swift Package Manager (GitHub)
```swift
dependencies: [
    .package(url: "https://github.com/your-org/core-ios-sdk.git", from: "1.0.11")
]
```

### Swift Package Registry (New!)
```swift
dependencies: [
    .package(id: "com.cashfree.CashfreePG", from: "1.0.11")
]
```

### CocoaPods (Existing)
```ruby
pod 'CashfreePG', '~> 1.0.11'
```

## 🎯 Three Swift Package Registry Options Compared

| Approach | Authentication | Deletion | Setup |
|----------|---------------|----------|-------|
| **GitHub Action** ⭐ | ❌ None | Manual | None |
| **GitHub App** | ❌ None | Manual | Install app |
| **Manual Token** | ✅ Token needed | Manual | Complex |

**Your current setup (GitHub Action) is the simplest!**

## 🔧 Technical Details

### Workflow Steps Verified ✅

The current workflow performs these exact steps:

1. **Checkout Code** - `actions/checkout@v4`
2. **Setup Xcode** - `maxim-lobanov/setup-xcode@v1` (latest-stable)
3. **Get Version** - Extracts tag name and version
4. **Print Info** - Shows package name and version
5. **Validate Package.swift** - `swift package dump-package`
6. **Resolve Dependencies** - `swift package resolve`
7. **Build Package** - `swift build`
8. **Run Tests** - `swift test` (if test targets exist)
9. **Validate XCFrameworks** - Checks Info.plist in each framework
10. **Publish to Registry** - Uses GitHub Action with no authentication
11. **Summary Report** - Shows results in GitHub Actions

### Supported Platforms
- **iOS:** 12.0+
- **Swift:** 5.7+
- **Xcode:** Latest stable version
- **Runner:** macOS-latest

### XCFramework Validation
The workflow validates:
- Info.plist presence and structure
- Framework directory structure
- Binary architecture support
- Platform compatibility

## 🔍 Monitoring & Troubleshooting

### **Check Workflow Status**
1. Go to repository → **Actions** tab
2. Look for **"Swift Package Registry Sync"**
3. Click on the run to see detailed logs
4. Each step shows success/failure status

### **Verify Publication**
1. Check [Swift Package Registry](https://swiftpackageregistry.com)
2. Search for "CashfreePG"
3. Verify your version appears

### **Common Issues & Solutions**

#### 1. Package.swift Validation Fails
```bash
Problem: Syntax errors in Package.swift
Solution: Run locally: swift package dump-package
Check: Swift tools version compatibility
```

#### 2. XCFramework Validation Fails
```bash
Problem: Missing Info.plist files
Solution: Ensure each *.xcframework/Info.plist exists
Check: Framework structure is valid
```

#### 3. Build Fails
```bash
Problem: Dependencies don't resolve
Solution: Run locally: swift package resolve
Check: All dependencies are accessible
```

#### 4. GitHub Action Fails
```bash
Problem: Registry publication fails
Solution: Check GitHub Actions logs
Verify: Repository has public access
```

## 🎉 Expected Results

After successful workflow execution:

1. ✅ **Package validated** and builds correctly
2. ✅ **Published to registry** at https://swiftpackageregistry.com
3. ✅ **Users can install** via multiple methods
4. ✅ **GitHub Actions summary** shows detailed results
5. ✅ **Available immediately** for Swift Package Manager

## 📋 Complete File Structure

```
.github/
├── workflows/
│   ├── README.md (📚 Complete guide)
│   ├── swift-package-release.yml (🚀 Auto-publish)
│   ├── swift-package-validation.yml (✅ Validation)
│   └── swift-package-delete.yml (🗑️ Deletion helper)
```

## 🚀 Current Workflow Status

### **✅ What Works Automatically:**
- Package validation
- Swift Package Registry publication  
- No authentication required
- Immediate availability

### **⚠️ What Requires Manual Action:**
- Package deletion from registry
- Git tag deletion
- GitHub release deletion

## 📚 Additional Resources

- [Swift Package Registry](https://swiftpackageregistry.com)
- [GitHub Action Documentation](https://github.com/marketplace/actions/swift-package-registry)
- [Swift Package Manager Guide](https://swift.org/package-manager/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## ✨ Quick Start

**Ready to use immediately:**

1. **Push a tag:** `git tag 1.0.11 && git push origin 1.0.11`
2. **Watch workflow:** Check Actions tab
3. **Verify publication:** Search https://swiftpackageregistry.com
4. **Share with users:** Provide installation instructions

**That's it!** No additional setup required. The workflow handles validation and publishing automatically. 🚀

## 🎉 Summary

1. **✅ NO SECRET KEYS NEEDED** - Your workflow works without authentication
2. **✅ DELETION WORKFLOW ADDED** - Helper for deletion instructions
3. **✅ AUTHENTICATION FIXED** - Removed unnecessary token parameter
4. **✅ READY TO USE** - Just push tags and it works!

**Your workflow is now optimized and requires zero configuration!**

---

*This workflow ensures your Swift package is automatically validated and synced to Swift Package Registry for seamless distribution.*
