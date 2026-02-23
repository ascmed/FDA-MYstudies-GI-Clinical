# iOS App Development Guide

Complete guide for continuing Phase 2 iOS app development.

## 📊 Progress Summary

### Completed ✅
- [x] Project architecture and structure
- [x] Core data models (User, Study, Survey, ConsentForm)
- [x] API service for backend communication
- [x] Authentication service and ViewModel
- [x] Storage service for offline data
- [x] Notification manager
- [x] Main UI navigation (TabView)
- [x] Dashboard view with study progress
- [x] Study list view
- [x] Survey list view
- [x] Settings view
- [x] Onboarding flow
- [x] Enrollment token entry view
- [x] Logging and utility extensions
- [x] CocoaPods configuration

### In Progress 🔄
- [ ] ResearchKit survey wrapper
- [ ] Consent form flow with e-signature
- [ ] Survey detail view
- [ ] Study detail view
- [ ] HealthKit integration

### Remaining ⏳
- [ ] Sync engine for offline data
- [ ] Unit and UI tests
- [ ] App Store submission configuration
- [ ] Push notification configuration
- [ ] Advanced analytics

---

## 🎯 Next Immediate Tasks

### 1. Create Study Detail View (2-3 hours)

**File:** `GIClinicalStudies/Views/StudyDetailView.swift`

```swift
struct StudyDetailView: View {
    let study: Study
    @State private var showingConsentFlow = false
    @StateObject private var viewModel = StudyDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Study header with progress
                StudyHeaderCard(study: study, metrics: viewModel.metrics)

                // About section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About This Study")
                        .font(.headline)
                    Text(study.description ?? "")
                        .font(.body)
                        .foregroundColor(.gray)
                }

                // Requirements section
                VStack(alignment: .leading, spacing: 12) {
                    Text("What You'll Do")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        // Show surveys in this study
                        ForEach(viewModel.surveys) { survey in
                            Label(survey.title, systemImage: "checkmark.circle")
                        }
                    }
                }

                // Resources section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Resources")
                        .font(.headline)
                    VStack(spacing: 8) {
                        ForEach(viewModel.resources) { resource in
                            Link(destination: URL(string: resource.url ?? "")!) {
                                Label(resource.title, systemImage: resource.resourceType.icon)
                                    .foregroundColor(.primaryGreen)
                            }
                        }
                    }
                }

                // Action button
                if !viewModel.isEnrolled {
                    Button(action: { showingConsentFlow.toggle() }) {
                        Text("Review Consent & Enroll")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primaryGreen)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(study.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchStudyDetails(for: study.id)
        }
        .sheet(isPresented: $showingConsentFlow) {
            ConsentFlowView(study: study)
        }
    }
}
```

### 2. Create Survey Detail View (2-3 hours)

**File:** `GIClinicalStudies/Views/SurveyDetailView.swift`

```swift
struct SurveyDetailView: View {
    let survey: Survey
    @StateObject private var viewModel = SurveyViewModel()
    @State private var showingResearchKit = false

    var body: some View {
        VStack {
            if showingResearchKit {
                ResearchKitSurveyController(survey: survey)
                    .edgesIgnoringSafeArea(.all)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Survey info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(survey.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            if let description = survey.description {
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }

                            HStack(spacing: 12) {
                                Label(survey.frequency.displayName, systemImage: "calendar")
                                Label("\(survey.questions?.count ?? 0) questions", systemImage: "questionmark.circle")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }

                        Divider()

                        // Survey questions preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Questions")
                                .font(.headline)

                            ForEach(survey.questions?.prefix(3) ?? [], id: \.id) { question in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(question.questionText)
                                        .font(.body)
                                        .fontWeight(.semibold)

                                    Text(question.questionType.displayName)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(16)
                }

                // Start button
                Button(action: { showingResearchKit.toggle() }) {
                    Text("Begin Survey")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(16)
            }
        }
        .navigationTitle("Survey")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

### 3. Create ResearchKit Survey Wrapper (3-4 hours)

**File:** `GIClinicalStudies/Views/ResearchKitSurveyController.swift`

```swift
import UIKit
import ResearchKit

struct ResearchKitSurveyController: UIViewControllerRepresentable {
    let survey: Survey

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let steps = survey.questions?.map { $0.toORKQuestion() } ?? []
        let task = ORKOrderedTask(identifier: survey.id, steps: steps)

        let taskVC = ORKTaskViewController(task: task, taskRun: nil)
        taskVC.delegate = context.coordinator

        return taskVC
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {
        // Update if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(survey: survey)
    }

    class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let survey: Survey

        init(survey: Survey) {
            self.survey = survey
        }

        func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
            // Handle survey completion
            if reason == .completed {
                // Save responses
                // Submit to backend
            }
            taskViewController.dismiss(animated: true)
        }
    }
}
```

### 4. Create Consent Flow (2-3 hours)

**File:** `GIClinicalStudies/Views/ConsentFlowView.swift`

```swift
struct ConsentFlowView: View {
    let study: Study
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ConsentViewModel()
    @State private var currentStep: ConsentStep = .review

    var body: some View {
        ZStack {
            switch currentStep {
            case .review:
                ConsentReviewView(
                    consentForm: viewModel.consentForm,
                    onNext: { currentStep = .signature }
                )

            case .signature:
                ConsentSignatureView(
                    study: study,
                    onSign: { signature in
                        viewModel.submitConsent(signature: signature)
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            viewModel.fetchConsentForm(for: study.id)
        }
    }
}

enum ConsentStep {
    case review
    case signature
}
```

---

## 📋 Implementation Checklist

### Phase 2A: Core Views (Week 1)
- [ ] Implement StudyDetailView
- [ ] Implement SurveyDetailView
- [ ] Create ResearchKit wrapper
- [ ] Basic survey completion flow
- [ ] Test navigation

### Phase 2B: Consent Flow (Week 2)
- [ ] Implement ConsentFlowView
- [ ] Add e-signature capture
- [ ] PDF consent generation
- [ ] Consent submission to backend
- [ ] Test consent workflow

### Phase 2C: Data Sync (Week 2-3)
- [ ] Implement SyncEngine
- [ ] Offline survey saving
- [ ] Background sync
- [ ] Conflict resolution
- [ ] Test offline scenarios

### Phase 2D: HealthKit (Week 3)
- [ ] Create HealthKitService
- [ ] Request HealthKit permissions
- [ ] Auto-populate survey fields
- [ ] Health data export
- [ ] Test with Apple Health

### Phase 2E: Testing (Week 4)
- [ ] Write unit tests
- [ ] Write UI tests
- [ ] Test on real device
- [ ] Beta testing
- [ ] Bug fixes

---

## 🔧 Current File Structure

```
GIClinicalStudies/
├── App/
│   └── GIClinicalStudiesApp.swift ✅
├── Models/
│   ├── User.swift ✅
│   ├── Study.swift ✅
│   ├── Survey.swift ✅
│   └── ConsentForm.swift ✅
├── ViewModels/
│   ├── AuthViewModel.swift ✅
│   └── StudyViewModel.swift ✅
├── Views/
│   ├── MainTabView.swift ✅
│   ├── OnboardingView.swift ✅
│   ├── EnrollmentTokenView.swift ✅
│   ├── DashboardView.swift ✅
│   ├── StudyListView.swift ✅
│   ├── SurveyListView.swift ✅
│   ├── SettingsView.swift ✅
│   ├── StudyDetailView.swift (TODO)
│   ├── SurveyDetailView.swift (TODO)
│   ├── ConsentFlowView.swift (TODO)
│   └── ResearchKitSurveyController.swift (TODO)
├── Services/
│   ├── APIService.swift ✅
│   ├── StorageService.swift ✅
│   ├── NotificationManager.swift ✅
│   ├── SyncEngine.swift (TODO)
│   └── HealthKitService.swift (TODO)
└── Utilities/
    ├── Logger.swift ✅
    └── Extensions.swift ✅
```

---

## 🧪 Testing Strategy

### Unit Tests
```swift
// Test API calls
// Test data models
// Test view models
// Test storage
```

### UI Tests
```swift
// Test navigation flows
// Test form inputs
// Test survey completion
// Test consent flow
```

### Integration Tests
```swift
// Test end-to-end enrollment
// Test survey submission
// Test offline sync
```

---

## 🚀 Deployment Checklist

Before App Store submission:
- [ ] All views implemented
- [ ] All features tested
- [ ] Performance optimized
- [ ] Privacy policy updated
- [ ] Data security verified
- [ ] Crash reporting configured
- [ ] Analytics working
- [ ] Push notifications configured
- [ ] App icons added
- [ ] Screenshots created
- [ ] Beta testing complete

---

## 📞 Common Issues & Solutions

### ResearchKit Integration Issues
- Ensure ResearchKit pod is installed
- Use `makeUIViewController` for proper lifecycle
- Handle task completion in coordinator

### Storage Issues
- Use Keychain for auth tokens
- Use CoreData for survey data
- Test offline scenarios

### API Connection Issues
- Add error handling
- Implement retry logic
- Test with simulator network conditions

---

## 🎯 Estimated Timeline

- **Week 1:** Core views (Study, Survey detail)
- **Week 2:** Consent flow + ResearchKit
- **Week 3:** Data sync + HealthKit
- **Week 4:** Testing + Refinement
- **Week 5:** App Store submission

**Total:** 4-5 weeks for full implementation

---

## 📚 Resources

- [ResearchKit Documentation](https://github.com/ResearchKit/ResearchKit)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Apple HealthKit](https://developer.apple.com/health/)
- [App Store Connect Guide](https://developer.apple.com/app-store/app-store-connect/)

---

**Status:** Ready for Week 1 development
**Version:** 1.0.0
