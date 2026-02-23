# iOS App Setup Guide

Complete instructions for building and deploying the GI Clinical Studies iOS Patient App.

## 📋 Prerequisites

- **Xcode 14+** (with iOS 14+ SDK)
- **macOS 12+**
- **CocoaPods** (`gem install cocoapods`)
- **Apple Developer Account** ($99/year)
- **Provisioning Profiles** from Apple Developer
- **APNS Certificate** for push notifications

## 🚀 Step 1: Project Setup

### 1.1 Create Xcode Project

```bash
cd /path/to/FDA study app by claude/ios-patient-app

# Create project structure
mkdir -p GIClinicalStudies/App
mkdir -p GIClinicalStudies/Models
mkdir -p GIClinicalStudies/ViewModels
mkdir -p GIClinicalStudies/Views
mkdir -p GIClinicalStudies/Services
mkdir -p GIClinicalStudies/Utilities
mkdir -p GIClinicalStudies/Resources
mkdir -p GIClinicalStudiesTests
```

### 1.2 Install Dependencies

```bash
pod install
```

This installs:
- **ResearchKit** - Survey and consent forms
- **Alamofire** - HTTP networking
- **KeychainAccess** - Secure credential storage
- **Realm** - Local database
- **Firebase** - Push notifications & analytics

### 1.3 Open Xcode Workspace

```bash
open GIClinicalStudies.xcworkspace
```

**Important:** Always use the `.xcworkspace` file, not `.xcodeproj`

## 🔑 Step 2: Configure Credentials

### 2.1 Create Config File

Create `GIClinicalStudies/Config.swift`:

```swift
import Foundation

struct Config {
    #if DEBUG
    static let apiBaseURL = "http://localhost:5000/api"
    #else
    static let apiBaseURL = "https://api.giclinicalstudies.com/api"
    #endif

    static let appName = "GI Clinical Studies"
    static let bundleIdentifier = "com.giclinicalstudies.app"
}
```

### 2.2 Set Bundle Identifier

1. Open `GIClinicalStudies.xcworkspace`
2. Select project > GIClinicalStudies target
3. In General tab, set Bundle Identifier
4. Must match your Apple Developer provisioning profile

### 2.3 Configure Code Signing

1. Select project > GIClinicalStudies target
2. Go to Signing & Capabilities
3. Select Team (your Apple Developer account)
4. Ensure provisioning profile is selected

## 📱 Step 3: Configure Push Notifications

### 3.1 Create APNS Certificate

1. Go to [Apple Developer](https://developer.apple.com/)
2. Certificates, Identifiers & Profiles
3. Identifiers → Select your app
4. Capabilities → Push Notifications
5. Configure production/development certificates
6. Download `.cer` files

### 3.2 Convert to `.p8` (Recommended)

```bash
# Apple Notification service authentication key (preferred)
# Download from Apple Developer > Keys section
```

### 3.3 Configure in Xcode

1. Select GIClinicalStudies target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Add "Push Notifications"

## 🧪 Step 4: Build & Test

### 4.1 Build for Simulator

```bash
xcodebuild -workspace GIClinicalStudies.xcworkspace \
  -scheme GIClinicalStudies \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

Or in Xcode: **Product → Build** (⌘B)

### 4.2 Run on Simulator

1. Select target device (iPhone 14+)
2. Press **Play** button or **Cmd + R**
3. App launches on simulator

### 4.3 Build for Device

1. Connect iPhone
2. Select device in Xcode
3. Press Play or **Cmd + R**

**Note:** Requires valid Apple Developer certificate and provisioning profile

## 🔧 Step 5: Backend Configuration

### 5.1 Update API Base URL

**For Development:**
```swift
// In APIService.swift
#if DEBUG
self.baseURL = URL(string: "http://localhost:5000/api")!
#else
self.baseURL = URL(string: "https://api.giclinicalstudies.com/api")!
#endif
```

**For Production:**
Update the HTTPS URL to your production server

### 5.2 Ensure Backend is Running

```bash
cd /path/to/wcp-portal
npm run dev
# Backend running on http://localhost:5000
```

## 📝 Step 6: Testing

### 6.1 Unit Tests

```bash
# In Xcode
Cmd + U
```

Or from command line:
```bash
xcodebuild -workspace GIClinicalStudies.xcworkspace \
  -scheme GIClinicalStudies \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  test
```

### 6.2 UI Tests

```bash
# Record and run UI tests
xcodebuild -workspace GIClinicalStudies.xcworkspace \
  -scheme GIClinicalStudies \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  test -enableCodeCoverage YES
```

## 🚢 Step 7: Deployment

### 7.1 Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Apps → My Apps → Create App
3. Bundle ID: `com.giclinicalstudies.app`
4. SKU: (use bundle ID)
5. Save

### 7.2 Configure App Information

1. App Information → General
2. Set description, keywords, support URL
3. Add privacy policy URL
4. Set age rating

### 7.3 Build Archive

```bash
xcodebuild -workspace GIClinicalStudies.xcworkspace \
  -scheme GIClinicalStudies \
  -configuration Release \
  -archivePath build/GIClinicalStudies.xcarchive \
  archive
```

Or in Xcode:
1. Select Generic iOS Device
2. **Product → Archive**
3. Organizer window opens

### 7.4 Export for App Store

1. In Organizer, select latest build
2. Click **Distribute App**
3. Select **App Store Connect**
4. Follow export wizard
5. Upload to App Store

### 7.5 Submit for Review

1. In App Store Connect
2. Prepare for Submission
3. Set release version
4. Add release notes
5. Click **Submit for Review**

**Review typically takes 24-48 hours**

## 🐛 Troubleshooting

### Xcode Build Errors

**"No matching provisioning profile found"**
- Ensure bundle ID matches Apple Developer profile
- Check Signing & Capabilities in Xcode

**"CocoaPods installation failed"**
```bash
rm -rf Pods Podfile.lock
pod install
```

**"ResearchKit not found"**
```bash
# Ensure workspace is opened, not project
open GIClinicalStudies.xcworkspace
```

### Runtime Errors

**"Network request failed"**
- Ensure backend is running
- Check API base URL configuration
- Verify HTTPS certificates (production)

**"Permission denied"**
- Grant app camera, microphone, Health access
- Check Info.plist permissions
- Ensure user grants permissions on first run

### Push Notifications Not Working

- Verify APNS certificate is configured
- Check device token is registered
- Ensure push notification capability is enabled
- Verify app is signed with development team

## 📚 Documentation

- **[README.md](README.md)** - Overview and features
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture
- **[API Integration](API_INTEGRATION.md)** - Backend API reference
- **[Testing Guide](TESTING.md)** - Test strategy and implementation

## 🔐 Security Checklist

- [ ] Keychain used for auth tokens
- [ ] HTTPS enforced for all APIs
- [ ] Data encrypted at rest
- [ ] No PHI logged
- [ ] Biometric authentication enabled
- [ ] App Transport Security configured
- [ ] Secure random tokens used
- [ ] Session timeouts configured

## 📊 Performance Optimization

- **Memory:** Use weak references in ViewModels
- **Network:** Implement request caching
- **Storage:** Archive old survey responses
- **UI:** Use lazy loading for large lists
- **Battery:** Batch background syncs

## 🎯 Next Steps

1. ✅ Complete setup as above
2. 📱 Build and test on simulator
3. 📤 Submit test builds to TestFlight
4. 👥 Gather beta feedback
5. 🚀 Submit for App Store review
6. 📈 Monitor analytics and crashes

---

**Status:** Setup Ready
**Version:** 1.0.0
**Support:** Refer to Xcode documentation and ResearchKit examples
