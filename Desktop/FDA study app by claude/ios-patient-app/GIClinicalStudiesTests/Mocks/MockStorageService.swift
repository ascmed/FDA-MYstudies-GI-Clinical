import Foundation
@testable import GIClinicalStudies

/// Mock Storage Service for testing
class MockStorageService: StorageService {
    // In-memory storage
    var authToken: String?
    var userId: String?
    var savedSurveyResponses: [SurveyResponse] = []
    var savedConsentSignatures: [ConsentSignature] = []
    var cachedSurveyQuestions: [String: [String: AnyCodable]] = [:]
    var cachedConsentForms: [String: ConsentForm] = [:]

    // Tracking
    var saveAuthTokenCallCount = 0
    var retrieveAuthTokenCallCount = 0
    var saveConsentSignatureCallCount = 0
    var saveSurveyResponseCallCount = 0
    var getPendingSurveyResponsesCallCount = 0

    // Configuration
    var shouldFailKeychainOperations = false

    // Override methods
    override func saveAuthToken(_ token: String, forUser userId: String) throws {
        saveAuthTokenCallCount += 1

        if shouldFailKeychainOperations {
            throw StorageError.keychainError("Keychain operation failed")
        }

        self.authToken = token
        self.userId = userId
    }

    override func retrieveAuthToken(forUser userId: String) throws -> String? {
        retrieveAuthTokenCallCount += 1

        if shouldFailKeychainOperations {
            throw StorageError.keychainError("Keychain operation failed")
        }

        return authToken
    }

    override func deleteAuthToken(forUser userId: String) throws {
        if shouldFailKeychainOperations {
            throw StorageError.keychainError("Keychain operation failed")
        }

        authToken = nil
        self.userId = nil
    }

    override func saveConsentSignature(_ signature: ConsentSignature) throws {
        saveConsentSignatureCallCount += 1

        if shouldFailKeychainOperations {
            throw StorageError.keychainError("Keychain operation failed")
        }

        savedConsentSignatures.append(signature)
    }

    override func saveSurveyResponse(_ response: SurveyResponse, isSynced: Bool) throws {
        saveSurveyResponseCallCount += 1
        savedSurveyResponses.append(response)
    }

    override func getPendingSurveyResponses() -> [SurveyResponse] {
        getPendingSurveyResponsesCallCount += 1
        return savedSurveyResponses.filter { !$0.isSynced }
    }

    override func markResponseAsSynced(responseId: String) throws {
        if let index = savedSurveyResponses.firstIndex(where: { $0.id == responseId }) {
            savedSurveyResponses[index].isSynced = true
        }
    }

    override func cacheSurveyQuestions(_ questions: [String: AnyCodable], forSurvey surveyId: String) {
        cachedSurveyQuestions[surveyId] = questions
    }

    override func getCachedSurveyQuestions(forSurvey surveyId: String) -> [String: AnyCodable]? {
        return cachedSurveyQuestions[surveyId]
    }

    override func cacheConsentForm(_ form: ConsentForm, forStudy studyId: String) {
        cachedConsentForms[studyId] = form
    }

    override func getCachedConsentForm(forStudy studyId: String) -> ConsentForm? {
        return cachedConsentForms[studyId]
    }

    // Helper methods for testing
    func reset() {
        authToken = nil
        userId = nil
        savedSurveyResponses.removeAll()
        savedConsentSignatures.removeAll()
        cachedSurveyQuestions.removeAll()
        cachedConsentForms.removeAll()
        saveAuthTokenCallCount = 0
        retrieveAuthTokenCallCount = 0
        saveConsentSignatureCallCount = 0
        saveSurveyResponseCallCount = 0
        getPendingSurveyResponsesCallCount = 0
        shouldFailKeychainOperations = false
    }

    func getAllResponses() -> [SurveyResponse] {
        return savedSurveyResponses
    }

    func getAllSignatures() -> [ConsentSignature] {
        return savedConsentSignatures
    }
}

// MARK: - Mock Models
struct ConsentSignature: Codable {
    let id: String
    let consentId: String
    let signedBy: String
    let signedAt: Date
    let signature: String
}

// MARK: - Storage Error
enum StorageError: LocalizedError {
    case keychainError(String)
    case encodingError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .keychainError(let message):
            return message
        case .encodingError:
            return "Failed to encode data"
        case .decodingError:
            return "Failed to decode data"
        }
    }
}
