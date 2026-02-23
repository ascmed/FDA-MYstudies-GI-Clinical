import Foundation
@testable import GIClinicalStudies

/// Mock API Service for testing
class MockAPIService: APIService {
    var loginCallCount = 0
    var getSurveyQuestionsCallCount = 0
    var submitSurveyResponseCallCount = 0
    var getConsentFormCallCount = 0
    var submitConsentCallCount = 0

    // Configuration for test scenarios
    var loginShouldFail = false
    var networkError: NSError?
    var responseDelay: TimeInterval = 0

    // Mock data
    var mockSurveyQuestions: [String: AnyCodable]?
    var mockConsentForm: ConsentForm?
    var mockAuthToken: String?

    // Track calls
    var lastLoginRequest: LoginRequest?
    var lastSurveyResponse: SurveyResponse?
    var lastConsentRequest: ConsentRequest?

    override func login(_ request: LoginRequest) async throws -> LoginResponse {
        loginCallCount += 1
        lastLoginRequest = request

        await Task.sleep(UInt64(responseDelay * 1_000_000_000))

        if loginShouldFail {
            throw APIError.authenticationFailed
        }

        if let error = networkError {
            throw error
        }

        return LoginResponse(
            userId: "test-user-\(UUID().uuidString)",
            authToken: mockAuthToken ?? "test-token-\(UUID().uuidString)",
            refreshToken: "test-refresh-token",
            expiresIn: 3600
        )
    }

    override func getSurveyQuestions(surveyId: String) async throws -> [String: AnyCodable] {
        getSurveyQuestionsCallCount += 1

        await Task.sleep(UInt64(responseDelay * 1_000_000_000))

        if let error = networkError {
            throw error
        }

        return mockSurveyQuestions ?? [:]
    }

    override func submitSurveyResponse(_ response: SurveyResponse) async throws {
        submitSurveyResponseCallCount += 1
        lastSurveyResponse = response

        await Task.sleep(UInt64(responseDelay * 1_000_000_000))

        if let error = networkError {
            throw error
        }
    }

    override func getConsentForm(studyId: String) async throws -> ConsentForm {
        getConsentFormCallCount += 1

        await Task.sleep(UInt64(responseDelay * 1_000_000_000))

        if let error = networkError {
            throw error
        }

        return mockConsentForm ?? ConsentForm(
            id: "test-consent",
            title: "Test Consent Form",
            html: "<html>Test</html>",
            version: 1
        )
    }

    override func submitConsent(_ request: ConsentRequest) async throws -> ConsentResponse {
        submitConsentCallCount += 1
        lastConsentRequest = request

        await Task.sleep(UInt64(responseDelay * 1_000_000_000))

        if let error = networkError {
            throw error
        }

        return ConsentResponse(
            consentId: "test-consent-\(UUID().uuidString)",
            status: "accepted",
            signedAt: Date()
        )
    }

    // Helper method to reset state
    func reset() {
        loginCallCount = 0
        getSurveyQuestionsCallCount = 0
        submitSurveyResponseCallCount = 0
        getConsentFormCallCount = 0
        submitConsentCallCount = 0
        loginShouldFail = false
        networkError = nil
        responseDelay = 0
        lastLoginRequest = nil
        lastSurveyResponse = nil
        lastConsentRequest = nil
    }
}

// MARK: - Mock Models
struct LoginResponse: Codable {
    let userId: String
    let authToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct ConsentResponse: Codable {
    let consentId: String
    let status: String
    let signedAt: Date
}
