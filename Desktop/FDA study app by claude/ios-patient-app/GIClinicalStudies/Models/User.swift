import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let enrollmentToken: String
    let studies: [String] // Study IDs
    let enrolledAt: Date
    let lastSyncDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case enrollmentToken = "enrollment_token"
        case studies
        case enrolledAt = "enrolled_at"
        case lastSyncDate = "last_sync_date"
    }

    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Enrollment Request
struct EnrollmentRequest: Codable {
    let token: String
    let deviceId: String
    let osVersion: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case token
        case deviceId = "device_id"
        case osVersion = "os_version"
        case appVersion = "app_version"
    }
}

// MARK: - Authentication Response
struct AuthResponse: Codable {
    let user: User
    let token: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case user
        case token
        case expiresIn = "expires_in"
    }
}

// MARK: - Session
struct Session: Codable {
    let token: String
    let expiresAt: Date
    let userId: String

    var isValid: Bool {
        expiresAt > Date()
    }

    var isExpiringSoon: Bool {
        let expirationWarning = TimeInterval(60 * 60) // 1 hour
        return expiresAt.timeIntervalSinceNow < expirationWarning
    }
}
