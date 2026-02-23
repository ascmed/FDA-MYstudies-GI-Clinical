# GI Clinical Studies - iOS Patient App (Phase 2)

Native iOS application for patients to participate in GI clinical studies (UC, CD, NASH) using Apple's ResearchKit framework.

## 🎯 Overview

This is the **patient-facing mobile app** where participants:
- Enroll in studies using enrollment tokens
- Review and e-sign informed consent forms
- Complete surveys and health assessments
- Track their disease activity
- Receive push notifications for scheduled surveys
- View their study progress and dashboard

## 🏗️ Architecture

```
iOS App (Phase 2)
├── Authentication
│   ├── Enrollment token entry
│   ├── Biometric login (Face ID / Touch ID)
│   └── Session management
│
├── Study Management
│   ├── Study selection
│   ├── Study details & resources
│   └── Progress tracking
│
├── Consent Flow
│   ├── Multi-page e-consent
│   ├── E-signature capture
│   └── PDF generation
│
├── Survey Engine
│   ├── ResearchKit surveys
│   ├── Offline data storage
│   └── Auto-submit when online
│
├── Dashboard
│   ├── Survey schedules
│   ├── Completion status
│   └── Disease metrics
│
└── Data Sync
    ├── Encrypted local storage
    ├── Server communication
    └── Background sync
```

## 📋 Technology Stack

- **Language:** Swift 5.5+
- **iOS Target:** iOS 14.0+
- **IDE:** Xcode 14+
- **Frameworks:**
  - ResearchKit (surveys, consent)
  - HealthKit (health data integration)
  - LocalAuthentication (biometric login)
  - CoreData (offline storage)
  - UserNotifications (push notifications)
  - Combine (reactive programming)
  - Network (HTTP requests)

## 🔐 Features

### Authentication
- ✅ Enrollment token input
- ✅ Biometric login (Face ID/Touch ID)
- ✅ Secure session management
- ✅ Auto-logout on inactivity

### Studies (UC, CD, NASH)
- ✅ Study discovery and enrollment
- ✅ Study details and resources
- ✅ Progress tracking
- ✅ Disease-specific metrics

### Informed Consent
- ✅ Multi-page consent forms
- ✅ E-signature capture
- ✅ PDF consent archiving
- ✅ HIPAA compliance

### Surveys
- ✅ ResearchKit-based surveys
- ✅ Multiple question types
- ✅ Conditional logic
- ✅ Offline support
- ✅ Auto-save functionality

### Dashboard
- ✅ Survey schedule view
- ✅ Completion progress
- ✅ Study metrics summary
- ✅ Notification center

### Health Integration
- ✅ HealthKit data access
- ✅ Auto-populated survey responses
- ✅ Activity tracking
- ✅ Health data export

### Data Management
- ✅ Local encrypted storage (CoreData)
- ✅ Offline survey completion
- ✅ Background sync
- ✅ Conflict resolution

### Notifications
- ✅ Push notifications (APNs)
- ✅ Survey reminders
- ✅ Study announcements
- ✅ Local notifications (offline)

## 📁 Project Structure

```
GIClinicalStudies/
├── GIClinicalStudies.xcodeproj
├── GIClinicalStudies/
│   ├── App/
│   │   ├── GIClinicalStudiesApp.swift
│   │   └── SceneDelegate.swift
│   │
│   ├── Modules/
│   │   ├── Authentication/
│   │   │   ├── Views/
│   │   │   │   ├── EnrollmentTokenView.swift
│   │   │   │   └── BiometricLoginView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── AuthViewModel.swift
│   │   │   └── Services/
│   │   │       └── AuthService.swift
│   │   │
│   │   ├── Studies/
│   │   │   ├── Views/
│   │   │   │   ├── StudyListView.swift
│   │   │   │   ├── StudyDetailView.swift
│   │   │   │   └── EnrollmentView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── StudyViewModel.swift
│   │   │   └── Services/
│   │   │       └── StudyService.swift
│   │   │
│   │   ├── Consent/
│   │   │   ├── Views/
│   │   │   │   ├── ConsentViewController.swift
│   │   │   │   └── SignatureView.swift
│   │   │   ├── ViewControllers/
│   │   │   │   └── ORKConsentController.swift
│   │   │   └── Services/
│   │   │       └── ConsentService.swift
│   │   │
│   │   ├── Surveys/
│   │   │   ├── Views/
│   │   │   │   ├── SurveyListView.swift
│   │   │   │   └── SurveyDetailView.swift
│   │   │   ├── ViewControllers/
│   │   │   │   └── ORKSurveyController.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── SurveyViewModel.swift
│   │   │   └── Services/
│   │   │       └── SurveyService.swift
│   │   │
│   │   ├── Dashboard/
│   │   │   ├── Views/
│   │   │   │   ├── DashboardView.swift
│   │   │   │   ├── ProgressView.swift
│   │   │   │   └── MetricsView.swift
│   │   │   └── ViewModels/
│   │   │       └── DashboardViewModel.swift
│   │   │
│   │   └── Settings/
│   │       ├── Views/
│   │       │   └── SettingsView.swift
│   │       └── ViewModels/
│   │           └── SettingsViewModel.swift
│   │
│   ├── Services/
│   │   ├── APIService.swift         # HTTP requests
│   │   ├── StorageService.swift     # CoreData
│   │   ├── HealthKitService.swift   # Health data
│   │   ├── NotificationService.swift # Push/Local notifications
│   │   └── SyncService.swift        # Data sync
│   │
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Study.swift
│   │   ├── Survey.swift
│   │   ├── ConsentForm.swift
│   │   ├── SurveyResponse.swift
│   │   └── AppError.swift
│   │
│   ├── Utilities/
│   │   ├── Constants.swift
│   │   ├── Extensions.swift
│   │   ├── Validators.swift
│   │   └── Logger.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Localizable.strings
│   │   └── Info.plist
│   │
│   └── Supporting Files/
│       └── main.swift
│
├── GIClinicalStudiesTests/
│   ├── AuthServiceTests.swift
│   ├── StudyServiceTests.swift
│   ├── StorageServiceTests.swift
│   └── ValidationTests.swift
│
├── Podfile                  # CocoaPods dependencies
├── Podfile.lock
├── .gitignore
├── README.md
└── ARCHITECTURE.md
```

## 🛠️ Setup Instructions

### Prerequisites
- Xcode 14+
- macOS 12+
- CocoaPods
- iOS 14+ deployment target

### Installation

1. **Clone the repository**
   ```bash
   cd /path/to/FDA study app by claude
   git clone <repo-url> ios-patient-app
   cd ios-patient-app
   ```

2. **Install dependencies**
   ```bash
   pod install
   ```

3. **Open Xcode project**
   ```bash
   open GIClinicalStudies.xcworkspace
   ```

4. **Configure credentials**
   - Create `Config.swift` with API endpoints
   - Set bundle ID for your provisioning profile
   - Configure APNs certificate for push notifications

5. **Build and run**
   ```
   Cmd + R in Xcode
   ```

## 📚 Key Components

### Authentication Service
Handles enrollment token validation, biometric login, and session management.

### Survey Engine
Wraps ResearchKit to deliver surveys from the WCP backend. Supports:
- Multiple question types
- Conditional logic
- Progress saving
- Offline completion

### Data Persistence
CoreData with encrypted storage for:
- Completed surveys
- User responses
- Enrollment data
- Study preferences

### API Integration
HTTP client that communicates with the Express.js backend:
- User authentication
- Study enrollment
- Survey retrieval
- Response submission

### Health Kit Integration
Seamlessly integrates with Apple Health:
- Activity data
- Weight tracking
- Sleep data
- Steps count

## 🔐 Security

- ✅ Data encryption at rest (CoreData)
- ✅ TLS for all network requests
- ✅ Biometric authentication
- ✅ Secure session tokens
- ✅ HIPAA compliance ready
- ✅ No PHI in logs
- ✅ App Transport Security enabled

## 📱 Device Support

- **Minimum iOS:** 14.0
- **Target Devices:** iPhone 11+
- **iPad:** Full support
- **Dark Mode:** Fully supported
- **Accessibility:** VoiceOver, Dynamic Type

## 🎨 UI/UX

- Uses native SwiftUI for modern interface
- ResearchKit for survey presentation
- Custom health dashboard
- Accessible (WCAG 2.1 AA)
- Localized for multiple languages

## 📊 App Analytics

Tracks (privacy-preserving):
- Survey completion rates
- App usage patterns
- Feature adoption
- Error rates
- Performance metrics

**Note:** No personal data is tracked

## 🧪 Testing

```bash
# Unit tests
Cmd + U

# UI tests
Cmd + Shift + U

# Code coverage
Product → Scheme → Edit Scheme → Test → Code Coverage
```

## 📝 API Integration

The app communicates with the backend WCP:

```swift
// Example: Enroll in study
POST /api/enrollment/enroll
{
  "token": "ABC123...",
  "studyId": "uuid"
}

// Example: Submit survey response
POST /api/responses/submit
{
  "surveyId": "uuid",
  "responses": [{...}],
  "timestamp": "2024-02-23T10:00:00Z"
}
```

## 🚀 Build & Deployment

### Development Build
```bash
xcodebuild -workspace GIClinicalStudies.xcworkspace \
  -scheme GIClinicalStudies \
  -configuration Debug
```

### Release Build
```bash
xcodebuild -workspace GIClinicalStudies.xcworkspace \
  -scheme GIClinicalStudies \
  -configuration Release \
  -archivePath build/GIClinicalStudies.xcarchive \
  archive
```

### App Store Submission
1. Create app in App Store Connect
2. Configure signing certificates
3. Create build archive
4. Submit for review
5. Wait for Apple approval (~24-48 hours)

## 📱 System Requirements

- iPhone: iOS 14.0 or later
- Storage: ~50 MB
- Network: HTTPS only
- Camera: For signature capture
- Microphone: Not required
- Location: Not required

## 🎯 MVP Features

For initial launch:
- [x] Enrollment with token
- [x] Study selection
- [x] E-consent signing
- [x] Survey completion
- [x] Data storage
- [x] Dashboard view
- [x] Offline support

## 🔄 Future Features

Phase 2.1:
- [ ] Push notifications
- [ ] Health Kit integration
- [ ] Advanced analytics
- [ ] Multi-language support

Phase 2.2:
- [ ] Widget support
- [ ] Siri shortcuts
- [ ] Apple Watch companion app
- [ ] AR-enhanced surveys

## 📞 Support

For setup issues or questions, refer to:
- Xcode documentation
- ResearchKit GitHub: https://github.com/ResearchKit/ResearchKit
- Apple documentation: https://developer.apple.com/

## 📄 License

Apache 2.0 (matching FDA MyStudies)

## 👥 Team

Built as Phase 2 of the FDA MyStudies platform for GI Clinical Studies.

---

**Status:** Ready for implementation
**Estimated Build Time:** 4-6 weeks (solo developer)
