# Cashfree iOS SDK Sample

![GitHub](https://img.shields.io/github/license/cashfree/core-ios-sdk) ![Discord](https://img.shields.io/discord/931125665669972018?label=discord) ![GitHub last commit (branch)](https://img.shields.io/github/last-commit/cashfree/core-ios-sdk/master) ![GitHub release (with filter)](https://img.shields.io/github/v/release/cashfree/core-ios-sdk?label=latest) ![GitHub forks](https://img.shields.io/github/forks/cashfree/core-ios-sdk) ![GitHub Repo stars](https://img.shields.io/github/stars/cashfree/core-ios-sdk)


![Sample Banner Image](https://maven.cashfree.com/images/github-header-image-ios.png)

## **Description** 

Sample integration project for Cashfree Payment Gateway's iOS SDK, facilitating seamless and secure payment processing within your iOS application.

## 🚀 Quick Start

### Requirements
- iOS 12.0+
- Xcode 14.0+
- Swift 5.7+

## 📦 Installation

### Swift Package Manager (Recommended)

The easiest way to integrate Cashfree iOS SDK is through Swift Package Manager:

#### **Method 1: Xcode GUI**
1. Open your project in Xcode
2. Go to **File** > **Add Package Dependencies**
3. Enter the repository URL: `https://github.com/cashfree/core-ios-sdk.git`
4. Select the version rule (recommend "Up to Next Major Version")
5. Choose the products you need:
   - `CashfreePG` - Complete Payment Gateway SDK (recommended)
   - `CashfreePGCoreSDK` - Core payment processing
   - `CashfreePGUISDK` - UI components
   - `CashfreeAnalyticsSDK` - Analytics and tracking
   - `CFNetworkSDK` - Networking layer

#### **Method 2: Package.swift**
Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/cashfree/core-ios-sdk.git", from: "2.2.4")
]
```

Then add to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "CashfreePG", package: "core-ios-sdk")
    ]
)
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'CashfreePG', '~> 2.2.4'
```

Then run:
```bash
pod install
```

## 🏗️ Framework Architecture

The Cashfree iOS SDK is built with a modular architecture:

```
CashfreePG (Main SDK)
    ├── CashfreePGUISDK (UI Components)
    │   └── CashfreePGCoreSDK (Core Payment Logic)
    │       └── CashfreeAnalyticsSDK (Analytics & Tracking)
    │           └── CFNetworkSDK (Networking Layer)
```

## 🔧 Usage

### Import the SDK

```swift
import CashfreePG
```

### Initialize Payment Session

```swift
// Create payment session
let session = CFSession.CFSessionBuilder()
    .setEnvironment(.sandbox) // or .production
    .setOrderId("ORDER_ID")
    .setOrderAmount(100.0)
    .setOrderCurrency("INR")
    .setCustomerDetails(customerName: "John Doe", 
                       customerPhone: "9999999999", 
                       customerEmail: "john@example.com")
    .build()

// Create payment object
let cashfreePG = CFPaymentGatewayService.getInstance()

// Set callback
cashfreePG.setCallback(self)

// Start payment
cashfreePG.doPayment(session, in: self)
```

### Handle Payment Callbacks

```swift
extension ViewController: CFResponseDelegate {
    func onPaymentVerify(_ orderID: String) {
        // Payment successful - verify on your server
        print("Payment successful for order: \(orderID)")
    }
    
    func onPaymentFailure(_ cfErrorResponse: CFErrorResponse, _ orderID: String) {
        // Payment failed
        print("Payment failed: \(cfErrorResponse.getMessage())")
    }
}
```

## 📱 Sample Applications

This repository includes comprehensive sample applications:

- **[Swift Sample Application](Swift+Sample+Application/)** - UIKit implementation
- **[SwiftUI Sample Application](SwiftUI+Sample+Application/)** - SwiftUI implementation

## 📚 Documentation

- **[SPM Integration Guide](SPM_INTEGRATION_GUIDE.md)** - Detailed SPM setup instructions
- **[API Documentation](https://docs.cashfree.com/docs/ios)** - Complete API reference  
- **[Migration Guide](https://docs.cashfree.com/docs/ios-sdk-migration-guide)** - Upgrading from older versions

## 🛠️ Development

### For Contributors

If you want to contribute or modify the SDK:

1. Clone the repository:
```bash
git clone https://github.com/cashfree/core-ios-sdk.git
cd core-ios-sdk
```

2. Open the project in Xcode or use Swift Package Manager:
```bash
swift package resolve
swift build
```

### Release Process

We use automated releases with GitHub Actions. To create a new release:

1. Update version using the script:
```bash
./scripts/update_version.sh 2.2.5
```

2. The script will:
   - Update all podspec files
   - Create a git tag
   - Push to GitHub
   - Trigger automated release workflow

### Setting Up Your Own Repository

To set up this SDK in your own GitHub repository:

1. Run the setup script:
```bash
./scripts/github_setup.sh
```

2. Follow the interactive prompts to:
   - Create GitHub repository
   - Configure remote origin
   - Make initial commit
   - Create first release

## Getting help

If you have questions, concerns, bug reports, etc, you can reach out to us using one of the following 

1. File an issue in this repository's Issue Tracker.
2. Send a message in our discord channel. Join our [discord server](https://discord.gg/znT6X45qDS) to get connected instantly.
3. Send an email to care@cashfree.com

## Getting involved

For general instructions on _how_ to contribute please refer to [CONTRIBUTING](CONTRIBUTING.md).


----

## Open source licensing and other misc info
1. [LICENSE](https://github.com/cashfree/core-ios-sdk/blob/master/LICENSE.md)
2. [CODE OF CONDUCT](https://github.com/cashfree/core-ios-sdk/blob/master/CODE_OF_CONDUCT.md)
