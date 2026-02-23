import SwiftUI
import PDFKit

// MARK: - Consent Flow View
struct ConsentFlowView: View {
    let study: Study
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ConsentFlowViewModel()
    @State private var currentStep: ConsentStep = .review

    var body: some View {
        ZStack {
            Color.lightGreen.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Indicator
                ConsentProgressIndicator(currentStep: currentStep)
                    .padding(.vertical, 16)

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch currentStep {
                        case .review:
                            ConsentReviewView(
                                consentForm: viewModel.consentForm,
                                study: study,
                                isLoading: viewModel.isLoading,
                                onNext: { currentStep = .confirmation }
                            )

                        case .confirmation:
                            ConsentConfirmationView(
                                consentForm: viewModel.consentForm,
                                study: study,
                                onNext: { currentStep = .signature }
                            )

                        case .signature:
                            ConsentSignatureView(
                                study: study,
                                consentForm: viewModel.consentForm,
                                isLoading: viewModel.isLoading,
                                onSign: { signature in
                                    viewModel.submitConsent(signature: signature)
                                    onComplete?()
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                Spacer()
            }

            // Error Alert
            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.accentOrange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.dark)

                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }

                        Spacer()

                        Button(action: { viewModel.errorMessage = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(12)
                    .background(Color.accentOrange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(16)
                .background(Color.white)
            }
        }
        .navigationTitle("Informed Consent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if currentStep != .review {
                    Button("Back") {
                        if currentStep == .signature {
                            currentStep = .confirmation
                        } else {
                            currentStep = .review
                        }
                    }
                    .foregroundColor(.primaryGreen)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.gray)
            }
        }
        .onAppear {
            viewModel.fetchConsentForm(for: study.id)
        }
    }
}

// MARK: - Consent Progress Indicator
struct ConsentProgressIndicator: View {
    let currentStep: ConsentStep

    var steps: [ConsentStep] = [.review, .confirmation, .signature]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(steps.indices, id: \.self) { index in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(
                                index <= steps.firstIndex(of: currentStep) ?? 0
                                    ? Color.primaryGreen
                                    : Color.gray.opacity(0.3)
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )

                        Text(steps[index].label)
                            .font(.caption2)
                            .foregroundColor(.dark)
                    }

                    if index < steps.count - 1 {
                        VStack {
                            Divider()
                                .frame(height: 2)
                                .background(
                                    index < steps.firstIndex(of: currentStep) ?? 0
                                        ? Color.primaryGreen
                                        : Color.gray.opacity(0.3)
                                )

                            Spacer()
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Consent Review View
struct ConsentReviewView: View {
    let consentForm: ConsentForm?
    let study: Study
    let isLoading: Bool
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Review Consent Form")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dark)

                Text("Please read the consent form carefully before proceeding")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Consent Content
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.primaryGreen)
                    Text("Loading consent form...")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
            } else if let form = consentForm {
                // Multi-page content or single content
                if let pages = form.pages, !pages.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(form.title)
                            .font(.headline)
                            .foregroundColor(.dark)

                        Divider()

                        ForEach(pages.sorted { $0.displayOrder < $1.displayOrder }) { page in
                            VStack(alignment: .leading, spacing: 8) {
                                if let pageTitle = page.title {
                                    Text(pageTitle)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.dark)
                                }

                                Text(page.content)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(nil)
                            }
                            .padding(12)
                            .background(Color(UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                } else {
                    // Single page content
                    VStack(alignment: .leading, spacing: 12) {
                        Text(form.title)
                            .font(.headline)
                            .foregroundColor(.dark)

                        Divider()

                        Text(form.content)
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineLimit(nil)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }

                // Study Information
                VStack(alignment: .leading, spacing: 12) {
                    Label("Study Information", systemImage: "book.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryGreen)

                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Study Name", value: study.displayName)
                        Divider().padding(.vertical, 4)
                        InfoRow(label: "Study ID", value: study.studyId)
                        Divider().padding(.vertical, 4)
                        InfoRow(label: "Version", value: "v\(form.version)")
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
            } else {
                Text("Unable to load consent form. Please try again.")
                    .font(.body)
                    .foregroundColor(.accentOrange)
                    .padding(16)
                    .background(Color.accentOrange.opacity(0.1))
                    .cornerRadius(12)
            }

            Spacer()

            // Next Button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("I Have Read and Understand")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(consentForm == nil || isLoading ? Color.gray : Color.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(consentForm == nil || isLoading)
        }
    }
}

// MARK: - Consent Confirmation View
struct ConsentConfirmationView: View {
    let consentForm: ConsentForm?
    let study: Study
    let onNext: () -> Void

    @State private var readConfirmed = false
    @State private var agreementConfirmed = false
    @State private var riskConfirmed = false
    @State private var privacyConfirmed = false

    var allConfirmed: Bool {
        readConfirmed && agreementConfirmed && riskConfirmed && privacyConfirmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Your Understanding")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dark)

                Text("Please confirm each statement below")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Confirmations
            VStack(spacing: 12) {
                ConfirmationCheckbox(
                    isChecked: $readConfirmed,
                    label: "I have read and understood the informed consent form",
                    icon: "checkmark.circle"
                )

                ConfirmationCheckbox(
                    isChecked: $agreementConfirmed,
                    label: "I agree to participate in this clinical study",
                    icon: "hand.raised"
                )

                ConfirmationCheckbox(
                    isChecked: $riskConfirmed,
                    label: "I understand the risks, benefits, and alternatives",
                    icon: "exclamationmark.triangle"
                )

                ConfirmationCheckbox(
                    isChecked: $privacyConfirmed,
                    label: "I understand my data will be kept confidential and secure",
                    icon: "lock.shield"
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)

            // Legal Notice
            VStack(alignment: .leading, spacing: 8) {
                Label("Legal Notice", systemImage: "scale.3d")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dark)

                Text("Your participation is voluntary. You may withdraw at any time without penalty or loss of benefits. This study is conducted in compliance with FDA regulations and Good Clinical Practice guidelines.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(nil)
            }
            .padding(16)
            .background(Color(UIColor(red: 0.91, green: 0.96, blue: 0.94, alpha: 1.0)))
            .cornerRadius(12)

            Spacer()

            // Next Button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("Continue to Signature")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(allConfirmed ? Color.primaryGreen : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!allConfirmed)
        }
    }
}

// MARK: - Confirmation Checkbox Component
struct ConfirmationCheckbox: View {
    @Binding var isChecked: Bool
    let label: String
    let icon: String

    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? .primaryGreen : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.body)
                        .foregroundColor(.dark)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(12)
            .background(isChecked ? Color.primaryGreen.opacity(0.1) : Color(UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)))
            .cornerRadius(8)
        }
    }
}

// MARK: - Consent Signature View (Enhanced)
struct ConsentSignatureView: View {
    let study: Study
    let consentForm: ConsentForm?
    let isLoading: Bool
    let onSign: (ConsentSignature) -> Void

    @State private var signatureName = ""
    @State private var agreementConfirmed = false
    @FocusState private var isNameFocused: Bool

    var isFormValid: Bool {
        !signatureName.trimmingCharacters(in: .whitespaces).isEmpty && agreementConfirmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign Consent Form")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dark)

                Text("Enter your name and agree to participate")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Name Input
            VStack(alignment: .leading, spacing: 8) {
                Label("Full Name", systemImage: "person.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dark)

                TextField("Enter your full name", text: $signatureName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
                    .padding(.horizontal, 4)

                Text("Your name will serve as your electronic signature")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)

            // Signature Information
            VStack(alignment: .leading, spacing: 12) {
                Label("Signature Information", systemImage: "doc.text.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dark)

                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        label: "Signature Date",
                        value: Date().formatted(date: .abbreviated, time: .omitted)
                    )

                    Divider()

                    InfoRow(
                        label: "Study",
                        value: study.displayName
                    )

                    Divider()

                    InfoRow(
                        label: "Form Version",
                        value: "v\(consentForm?.version ?? 1)"
                    )

                    Divider()

                    InfoRow(
                        label: "Signature Type",
                        value: "Electronic"
                    )
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)

            // Final Agreement
            Button(action: { agreementConfirmed.toggle() }) {
                HStack(spacing: 12) {
                    Image(systemName: agreementConfirmed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(agreementConfirmed ? .primaryGreen : .gray)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Final Agreement")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.dark)

                        Text("By signing, I acknowledge that I have reviewed the consent form and agree to participate in this study. I understand my rights and responsibilities as a research participant.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(nil)
                    }

                    Spacer()
                }
                .padding(12)
                .background(agreementConfirmed ? Color.primaryGreen.opacity(0.1) : Color(UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)))
                .cornerRadius(8)
            }

            Spacer()

            // Submit Button
            Button(action: submitSignature) {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Submitting...")
                            .fontWeight(.semibold)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Sign & Submit Consent")
                            .fontWeight(.semibold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isFormValid && !isLoading ? Color.primaryGreen : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(!isFormValid || isLoading)
        }
    }

    private func submitSignature() {
        let signature = ConsentSignature(
            id: UUID().uuidString,
            consentFormId: consentForm?.id ?? "",
            participantId: "", // Will be populated from auth context
            signatureName: signatureName.trimmingCharacters(in: .whitespaces),
            signatureImage: nil,
            signedAt: Date(),
            ipAddress: nil
        )

        onSign(signature)
    }
}

// MARK: - Consent Step Enum
enum ConsentStep {
    case review
    case confirmation
    case signature

    var label: String {
        switch self {
        case .review:
            return "Review"
        case .confirmation:
            return "Confirm"
        case .signature:
            return "Sign"
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.dark)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        ConsentFlowView(
            study: Study(
                id: UUID().uuidString,
                studyId: "GI-UC-2026",
                title: "Ulcerative Colitis Study",
                description: "A comprehensive study on ulcerative colitis treatment",
                diseaseArea: "UC",
                phase: "Phase III",
                durationWeeks: 52,
                status: .published,
                createdAt: Date(),
                enrolledAt: Date(),
                completionPercentage: 0,
                color: "#C2410C"
            )
        )
    }
}
