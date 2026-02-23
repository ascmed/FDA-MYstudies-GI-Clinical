import Foundation
import ResearchKit

// MARK: - Consent Form
struct ConsentForm: Codable, Identifiable {
    let id: String
    let studyId: String
    let title: String
    let content: String
    let requiresSignature: Bool
    let signatureDateCaptured: Bool
    let version: Int
    let pages: [ConsentPage]?
    let createdAt: Date
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case studyId = "study_id"
        case title
        case content
        case requiresSignature = "requires_signature"
        case signatureDateCaptured = "signature_date_captured"
        case version
        case pages
        case createdAt = "created_at"
        case isActive = "is_active"
    }

    func toORKConsentDocument() -> ORKConsentDocument {
        let document = ORKConsentDocument()

        // Set sections from pages
        if let pages = pages {
            document.sections = pages.map { page in
                let section = ORKConsentSection(
                    type: .custom
                )
                section.title = page.title ?? title
                section.content = page.content

                return section
            }
        } else {
            // Single section from content
            let section = ORKConsentSection(type: .custom)
            section.title = title
            section.content = content
            document.sections = [section]
        }

        // Add signature info if required
        if requiresSignature {
            let signature = ORKConsentSignature(
                forPersonWithTitle: "Participant",
                dateFormatString: "MM/dd/yyyy",
                identifier: "ParticipantSignature"
            )
            document.addSignature(signature)
        }

        document.title = title

        return document
    }
}

// MARK: - Consent Page
struct ConsentPage: Codable, Identifiable {
    let id: String
    let consentFormId: String
    let pageNumber: Int
    let title: String?
    let content: String
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case consentFormId = "consent_form_id"
        case pageNumber = "page_number"
        case title
        case content
        case displayOrder = "display_order"
    }
}

// MARK: - Consent Signature
struct ConsentSignature: Codable, Identifiable {
    let id: String
    let consentFormId: String
    let participantId: String
    let signatureName: String
    let signatureImage: String? // Base64 encoded image
    let signedAt: Date
    let ipAddress: String?

    enum CodingKeys: String, CodingKey {
        case id
        case consentFormId = "consent_form_id"
        case participantId = "participant_id"
        case signatureName = "signature_name"
        case signatureImage = "signature_image"
        case signedAt = "signed_at"
        case ipAddress = "ip_address"
    }
}

// MARK: - Consent Status
struct ConsentStatus: Codable {
    let studyId: String
    let participantId: String
    let consentFormId: String
    let isConsented: Boolean
    let consentVersion: Int
    let consentDate: Date?
    let revokedAt: Date?

    enum CodingKeys: String, CodingKey {
        case studyId = "study_id"
        case participantId = "participant_id"
        case consentFormId = "consent_form_id"
        case isConsented = "is_consented"
        case consentVersion = "consent_version"
        case consentDate = "consent_date"
        case revokedAt = "revoked_at"
    }

    var isValid: Bool {
        isConsented && revokedAt == nil
    }
}

// MARK: - Consent Request
struct ConsentRequest: Codable {
    let consentFormId: String
    let signatureName: String
    let signatureImage: String? // Base64 encoded
    let consentedAt: Date
    let ipAddress: String?

    enum CodingKeys: String, CodingKey {
        case consentFormId = "consent_form_id"
        case signatureName = "signature_name"
        case signatureImage = "signature_image"
        case consentedAt = "consented_at"
        case ipAddress = "ip_address"
    }
}
