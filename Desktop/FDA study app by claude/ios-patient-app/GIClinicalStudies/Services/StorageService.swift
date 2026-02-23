import Foundation
import RealmSwift
import KeychainAccess

// MARK: - Storage Service
class StorageService {
    static let shared = StorageService()

    private let keychain = Keychain(service: "com.giclinicalstudies.app")
    private let userDefaults = UserDefaults.standard
    private let keychainService = "GIClinicalStudiesAuth"

    private init() {}

    // MARK: - Auth Token (Keychain)

    func saveAuthToken(_ token: String) {
        do {
            try keychain.set(token, key: "authToken")
        } catch {
            Logger.error("Failed to save auth token: \(error)")
        }
    }

    func getAuthToken() -> String? {
        try? keychain.get("authToken")
    }

    func clearAuthToken() {
        do {
            try keychain.remove("authToken")
        } catch {
            Logger.error("Failed to clear auth token: \(error)")
        }
    }

    // MARK: - User Data (UserDefaults)

    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: "currentUser")
        }
    }

    func getUser() -> User? {
        guard let data = userDefaults.data(forKey: "currentUser") else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func clearUser() {
        userDefaults.removeObject(forKey: "currentUser")
    }

    // MARK: - Studies (Realm)

    func saveStudies(_ studies: [Study]) {
        let realm = try! Realm()
        try! realm.write {
            // Convert to Realm objects and save
            // Implementation depends on Realm schema
        }
    }

    func getStudies() -> [Study] {
        // Fetch from Realm
        return []
    }

    // MARK: - Survey Responses (Realm)

    func saveSurveyResponse(_ response: SurveyResponse) throws {
        let realm = try Realm()
        try realm.write {
            // Convert SurveyResponse to Realm object
            // For now, we'll store as JSON in UserDefaults
            if let encoded = try? JSONEncoder().encode(response) {
                var responses = getAllSurveyResponses()
                responses.append(response)
                userDefaults.set(encoded, forKey: "surveyResponse_\(response.id)")
            }
        }
    }

    func getPendingSurveyResponses() -> [SurveyResponse] {
        let allResponses = getAllSurveyResponses()
        return allResponses.filter { !$0.isSynced }
    }

    func getAllSurveyResponses() -> [SurveyResponse] {
        // Retrieve all survey responses
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("surveyResponse_") }

        return keys.compactMap { key in
            guard let data = defaults.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(SurveyResponse.self, from: data)
        }
    }

    func markResponseAsSynced(responseId: String) throws {
        if let data = userDefaults.data(forKey: "surveyResponse_\(responseId)"),
           var response = try? JSONDecoder().decode(SurveyResponse.self, from: data) {
            var updatedResponse = response
            updatedResponse = SurveyResponse(
                id: response.id,
                surveyId: response.surveyId,
                participantId: response.participantId,
                responses: response.responses,
                completedAt: response.completedAt,
                isSynced: true
            )
            if let encoded = try? JSONEncoder().encode(updatedResponse) {
                userDefaults.set(encoded, forKey: "surveyResponse_\(responseId)")
            }
        }
    }

    func deleteSurveyResponse(responseId: String) throws {
        userDefaults.removeObject(forKey: "surveyResponse_\(responseId)")
    }

    // MARK: - Survey Questions Cache
    func saveSurveyQuestions(_ questions: [Question], for surveyId: String) throws {
        if let encoded = try? JSONEncoder().encode(questions) {
            userDefaults.set(encoded, forKey: "surveyQuestions_\(surveyId)")
        }
    }

    func getSurveyQuestions(for surveyId: String) -> [Question]? {
        guard let data = userDefaults.data(forKey: "surveyQuestions_\(surveyId)") else { return nil }
        return try? JSONDecoder().decode([Question].self, from: data)
    }

    // MARK: - Survey Cache
    func saveSurvey(_ survey: Survey) throws {
        if let encoded = try? JSONEncoder().encode(survey) {
            userDefaults.set(encoded, forKey: "survey_\(survey.id)")
        }
    }

    func getSurvey(id: String) throws -> Survey? {
        guard let data = userDefaults.data(forKey: "survey_\(id)") else { return nil }
        return try JSONDecoder().decode(Survey.self, from: data)
    }

    func getAllSurveys() throws -> [Survey] {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("survey_") && !$0.hasPrefix("surveyResponse_") && !$0.hasPrefix("surveyQuestions_") }

        return keys.compactMap { key in
            guard let data = defaults.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(Survey.self, from: data)
        }
    }

    func getUpcomingSurveys() throws -> [Survey] {
        let allSurveys = try getAllSurveys()
        let now = Date()
        return allSurveys.filter { survey in
            if let nextDate = survey.nextScheduledDate {
                return nextDate >= now
            }
            return false
        }
    }

    // MARK: - Preferences (UserDefaults)

    func setOnboardingCompleted(_ completed: Bool) {
        userDefaults.set(completed, forKey: "onboardingCompleted")
    }

    func hasCompletedOnboarding() -> Bool {
        userDefaults.bool(forKey: "onboardingCompleted")
    }

    func setSurveyNotificationEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: "surveyNotificationsEnabled")
    }

    func isSurveyNotificationEnabled() -> Bool {
        userDefaults.bool(forKey: "surveyNotificationsEnabled")
    }

    func savePushToken(_ token: String) {
        userDefaults.set(token, forKey: "pushToken")
    }

    func getPushToken() -> String? {
        userDefaults.string(forKey: "pushToken")
    }

    // MARK: - Consent Signatures (Keychain)

    func saveConsentSignature(_ signature: ConsentSignature) {
        do {
            let encoded = try JSONEncoder().encode(signature)
            try keychain.set(encoded, key: "consentSignature_\(signature.id)")
        } catch {
            Logger.error("Failed to save consent signature: \(error)")
        }
    }

    func getConsentSignature(_ id: String) -> ConsentSignature? {
        guard let data = try? keychain.getData("consentSignature_\(id)") else { return nil }
        return try? JSONDecoder().decode(ConsentSignature.self, from: data)
    }

    // MARK: - Cache Management

    func clearAllData() {
        clearAuthToken()
        clearUser()
        userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
    }

    func getCacheSize() -> Int64 {
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

        var totalSize: Int64 = 0
        if let enumerator = fileManager.enumerator(atPath: documentsPath) {
            for case let file as String in enumerator {
                let filePath = (documentsPath as NSString).appendingPathComponent(file)
                if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
                   let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
            }
        }

        return totalSize
    }
}
