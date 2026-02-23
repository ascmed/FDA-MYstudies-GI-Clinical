import Foundation
import Combine

// MARK: - API Service
class APIService {
    static let shared = APIService()

    private let baseURL: URL
    private var session: URLSession
    private var authToken: String?

    private init() {
        #if DEBUG
        self.baseURL = URL(string: "http://localhost:5000/api")!
        #else
        self.baseURL = URL(string: "https://api.giclinicalstudies.com/api")!
        #endif

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true

        self.session = URLSession(configuration: config)
        self.authToken = StorageService.shared.getAuthToken()
    }

    // MARK: - Public Methods

    func setAuthToken(_ token: String) {
        authToken = token
    }

    func clearAuthToken() {
        authToken = nil
    }

    // MARK: - Enrollment
    func enrollWithToken(_ token: String) -> AnyPublisher<AuthResponse, AppError> {
        let endpoint = baseURL.appendingPathComponent("enrollment/enroll")
        let request = EnrollmentRequest(
            token: token,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "",
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.appVersion
        )

        return post(endpoint, body: request, expecting: AuthResponse.self)
    }

    // MARK: - Studies
    func getStudies() -> AnyPublisher<[Study], AppError> {
        let endpoint = baseURL.appendingPathComponent("studies")
        return get(endpoint, expecting: [Study].self)
    }

    func getStudyDetails(_ studyId: String) -> AnyPublisher<StudyDetails, AppError> {
        let endpoint = baseURL.appendingPathComponent("studies/\(studyId)")
        return get(endpoint, expecting: StudyDetails.self)
    }

    // MARK: - Surveys
    func getSurveys(forStudy studyId: String) -> AnyPublisher<[Survey], AppError> {
        let endpoint = baseURL.appendingPathComponent("surveys/study/\(studyId)")
        return get(endpoint, expecting: [Survey].self)
    }

    func getSurvey(_ surveyId: String) -> AnyPublisher<Survey, AppError> {
        let endpoint = baseURL.appendingPathComponent("surveys/\(surveyId)")
        return get(endpoint, expecting: Survey.self)
    }

    func submitSurveyResponse(_ response: SurveyResponse) -> AnyPublisher<SubmitResponse, AppError> {
        let endpoint = baseURL.appendingPathComponent("responses/submit")
        return post(endpoint, body: response, expecting: SubmitResponse.self)
    }

    // MARK: - Consent
    func getConsentForm(forStudy studyId: String) -> AnyPublisher<ConsentForm, AppError> {
        let endpoint = baseURL.appendingPathComponent("consent/study/\(studyId)")
        return get(endpoint, expecting: ConsentForm.self)
    }

    func submitConsent(_ request: ConsentRequest) -> AnyPublisher<ConsentResponse, AppError> {
        let endpoint = baseURL.appendingPathComponent("consent/submit")
        return post(endpoint, body: request, expecting: ConsentResponse.self)
    }

    // MARK: - User
    func getCurrentUser() -> AnyPublisher<User, AppError> {
        let endpoint = baseURL.appendingPathComponent("users/me")
        return get(endpoint, expecting: User.self)
    }

    // MARK: - Push Notifications
    func registerPushToken(_ token: String) -> AnyPublisher<Void, AppError> {
        let endpoint = baseURL.appendingPathComponent("notifications/register")
        let request = ["deviceToken": token]

        return post(endpoint, body: request, expecting: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func get<T: Decodable>(_ url: URL, expecting: T.Type) -> AnyPublisher<T, AppError> {
        var request = URLRequest(url: url)
        addAuthHeader(&request)

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                try self.handleResponse(response)
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                self.mapError(error)
            }
            .eraseToAnyPublisher()
    }

    private func post<T: Decodable, B: Encodable>(
        _ url: URL,
        body: B,
        expecting: T.Type
    ) -> AnyPublisher<T, AppError> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(&request)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: AppError.encodingFailed).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                try self.handleResponse(response)
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                self.mapError(error)
            }
            .eraseToAnyPublisher()
    }

    private func addAuthHeader(_ request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func handleResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 401:
                throw AppError.unauthorized
            case 403:
                throw AppError.forbidden
            case 404:
                throw AppError.notFound
            default:
                throw AppError.serverError(statusCode: httpResponse.statusCode)
            }
        }
    }

    private func mapError(_ error: Error) -> AppError {
        if let error = error as? AppError {
            return error
        } else if error is DecodingError {
            return .decodingFailed
        } else {
            return .networkError(error.localizedDescription)
        }
    }
}

// MARK: - Response Models
struct SubmitResponse: Codable {
    let message: String
    let surveyId: String

    enum CodingKeys: String, CodingKey {
        case message
        case surveyId = "survey_id"
    }
}

struct ConsentResponse: Codable {
    let message: String
    let consentId: String

    enum CodingKeys: String, CodingKey {
        case message
        case consentId = "consent_id"
    }
}

struct EmptyResponse: Codable {}

// MARK: - Error Handling
enum AppError: LocalizedError {
    case networkError(String)
    case decodingFailed
    case encodingFailed
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingFailed:
            return "Failed to decode response"
        case .encodingFailed:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .notFound:
            return "Resource not found."
        case .serverError(let statusCode):
            return "Server error (Code: \(statusCode))"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
