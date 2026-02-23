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

    func saveSurveyResponse(_ response: SurveyResponse) {
        let realm = try! Realm()
        try! realm.write {
            // Save response
        }
    }

    func getPendingSurveyResponses() -> [SurveyResponse] {
        // Fetch unsync'd responses
        return []
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
