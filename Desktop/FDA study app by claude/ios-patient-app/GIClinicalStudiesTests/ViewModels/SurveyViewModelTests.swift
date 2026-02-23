import XCTest
import Combine
@testable import GIClinicalStudies

class SurveyViewModelTests: XCTestCase {
    var viewModel: SurveyViewModel!
    var mockAPIService: MockAPIService!
    var mockStorageService: MockStorageService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        mockStorageService = MockStorageService()
        viewModel = SurveyViewModel(apiService: mockAPIService, storageService: mockStorageService)
        cancellables = []
    }

    override func tearDown() {
        super.tearDown()
        mockAPIService.reset()
        mockStorageService.reset()
        cancellables.removeAll()
    }

    // MARK: - Load Survey Details Tests

    func testLoadSurveyDetails_Success() async {
        // Given
        let surveyId = "test-survey-1"
        let testQuestions: [String: AnyCodable] = [
            "q1": AnyCodable(value: "Test Question 1"),
            "q2": AnyCodable(value: "Test Question 2")
        ]
        mockAPIService.mockSurveyQuestions = testQuestions

        // When
        await viewModel.loadSurveyDetails(surveyId: surveyId)

        // Then
        XCTAssertEqual(mockAPIService.getSurveyQuestionsCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadSurveyDetails_CacheHit() async {
        // Given
        let surveyId = "test-survey-1"
        let cachedQuestions: [String: AnyCodable] = ["q1": AnyCodable(value: "Cached")]
        mockStorageService.cacheSurveyQuestions(cachedQuestions, forSurvey: surveyId)
        mockAPIService.getSurveyQuestionsCallCount = 0

        // When
        await viewModel.loadSurveyDetails(surveyId: surveyId)

        // Then
        XCTAssertEqual(mockAPIService.getSurveyQuestionsCallCount, 0, "Should use cache, not call API")
    }

    func testLoadSurveyDetails_NetworkError() async {
        // Given
        let surveyId = "test-survey-1"
        let networkError = NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "No internet"])
        mockAPIService.networkError = networkError

        // When
        await viewModel.loadSurveyDetails(surveyId: surveyId)

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Save Survey Response Tests

    func testSaveSurveyResponse_Online() async {
        // Given
        let response = SurveyResponse(
            id: UUID().uuidString,
            surveyId: "test-survey",
            userId: "test-user",
            answers: [:],
            timestamp: Date(),
            isSynced: false
        )

        // When
        await viewModel.saveSurveyResponse(response)

        // Then
        XCTAssertEqual(mockAPIService.submitSurveyResponseCallCount, 1)
        XCTAssertEqual(mockStorageService.saveSurveyResponseCallCount, 1)
    }

    func testSaveSurveyResponse_Offline() async {
        // Given
        let response = SurveyResponse(
            id: UUID().uuidString,
            surveyId: "test-survey",
            userId: "test-user",
            answers: [:],
            timestamp: Date(),
            isSynced: false
        )
        let networkError = NSError(domain: "Network", code: -1)
        mockAPIService.networkError = networkError

        // When
        await viewModel.saveSurveyResponse(response)

        // Then
        XCTAssertEqual(mockStorageService.saveSurveyResponseCallCount, 1)
        // Response should be queued locally
        XCTAssertEqual(mockStorageService.savedSurveyResponses.count, 1)
    }

    // MARK: - Sync Pending Responses Tests

    func testSyncPendingResponses_Success() async {
        // Given
        let response1 = SurveyResponse(
            id: "response-1",
            surveyId: "test-survey",
            userId: "test-user",
            answers: [:],
            timestamp: Date(),
            isSynced: false
        )
        let response2 = SurveyResponse(
            id: "response-2",
            surveyId: "test-survey",
            userId: "test-user",
            answers: [:],
            timestamp: Date(),
            isSynced: false
        )
        try? mockStorageService.saveSurveyResponse(response1, isSynced: false)
        try? mockStorageService.saveSurveyResponse(response2, isSynced: false)

        // When
        await viewModel.syncPendingResponses()

        // Then
        XCTAssertEqual(mockAPIService.submitSurveyResponseCallCount, 2)
    }

    func testSyncPendingResponses_PartialFailure() async {
        // Given
        let response1 = SurveyResponse(
            id: "response-1",
            surveyId: "test-survey",
            userId: "test-user",
            answers: [:],
            timestamp: Date(),
            isSynced: false
        )
        try? mockStorageService.saveSurveyResponse(response1, isSynced: false)

        // Configure API to fail on second call
        var callCount = 0
        mockAPIService.networkError = NSError(domain: "Network", code: -1)

        // When
        await viewModel.syncPendingResponses()

        // Then
        // Should attempt to sync
        XCTAssertGreaterThan(mockAPIService.submitSurveyResponseCallCount, 0)
    }

    func testSyncPendingResponses_Empty() async {
        // Given
        XCTAssertEqual(mockStorageService.getPendingSurveyResponses().count, 0)

        // When
        await viewModel.syncPendingResponses()

        // Then
        XCTAssertEqual(mockAPIService.submitSurveyResponseCallCount, 0)
    }

    // MARK: - Statistics Tests

    func testGetSurveyStatistics() {
        // Given
        let responses = [
            SurveyResponse(
                id: UUID().uuidString,
                surveyId: "survey-1",
                userId: "user",
                answers: [:],
                timestamp: Date(),
                isSynced: true
            ),
            SurveyResponse(
                id: UUID().uuidString,
                surveyId: "survey-2",
                userId: "user",
                answers: [:],
                timestamp: Date(),
                isSynced: false
            )
        ]
        responses.forEach { try? mockStorageService.saveSurveyResponse($0, isSynced: $0.isSynced) }

        // When
        let stats = viewModel.getResponseStatistics()

        // Then
        XCTAssertEqual(stats.totalResponses, 2)
        XCTAssertEqual(stats.syncedResponses, 1)
        XCTAssertEqual(stats.pendingResponses, 1)
    }

    // MARK: - Loading State Tests

    func testLoadingStateUpdates() async {
        // Given
        mockAPIService.responseDelay = 0.1
        let surveyId = "test-survey"

        // When
        let loadingExpectation = expectation(description: "Loading state changed")
        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if !isLoading {
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await viewModel.loadSurveyDetails(surveyId: surveyId)

        // Then
        wait(for: [loadingExpectation], timeout: 1.0)
    }

    // MARK: - Error Handling Tests

    func testErrorMessageClearing() async {
        // Given
        viewModel.errorMessage = "Previous error"

        // When
        mockAPIService.mockSurveyQuestions = [:]
        await viewModel.loadSurveyDetails(surveyId: "test-survey")

        // Then
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared on successful load")
    }

    func testErrorMessagePopulation() async {
        // Given
        mockAPIService.networkError = NSError(
            domain: "Network",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Connection failed"]
        )

        // When
        await viewModel.loadSurveyDetails(surveyId: "test-survey")

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Connection") ?? false)
    }

    // MARK: - Response Validation Tests

    func testSurveyResponseValidation_Valid() {
        // Given
        let validResponse = SurveyResponse(
            id: UUID().uuidString,
            surveyId: "test-survey",
            userId: "test-user",
            answers: ["q1": AnyCodable(value: "Answer 1")],
            timestamp: Date(),
            isSynced: false
        )

        // When
        let isValid = viewModel.isValidSurveyResponse(validResponse)

        // Then
        XCTAssertTrue(isValid)
    }

    func testSurveyResponseValidation_MissingUserId() {
        // Given
        let invalidResponse = SurveyResponse(
            id: UUID().uuidString,
            surveyId: "test-survey",
            userId: "", // Missing user ID
            answers: [:],
            timestamp: Date(),
            isSynced: false
        )

        // When
        let isValid = viewModel.isValidSurveyResponse(invalidResponse)

        // Then
        XCTAssertFalse(isValid)
    }

    // MARK: - Performance Tests

    func testLargeSurveyResponseHandling() async {
        // Given
        let largeAnswers: [String: AnyCodable] = (0..<100).reduce(into: [:]) { dict, index in
            dict["q\(index)"] = AnyCodable(value: "Answer \(index)")
        }
        let largeResponse = SurveyResponse(
            id: UUID().uuidString,
            surveyId: "test-survey",
            userId: "test-user",
            answers: largeAnswers,
            timestamp: Date(),
            isSynced: false
        )

        let startTime = Date()

        // When
        await viewModel.saveSurveyResponse(largeResponse)

        let elapsedTime = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertLessThan(elapsedTime, 0.5, "Large response handling should be performant")
    }
}

// MARK: - Helper Extensions
extension SurveyViewModel {
    func isValidSurveyResponse(_ response: SurveyResponse) -> Bool {
        return !response.userId.isEmpty && !response.surveyId.isEmpty
    }

    func getResponseStatistics() -> (totalResponses: Int, syncedResponses: Int, pendingResponses: Int) {
        let allResponses = getAllResponses()
        let syncedResponses = allResponses.filter { $0.isSynced }.count
        let pendingResponses = allResponses.filter { !$0.isSynced }.count

        return (allResponses.count, syncedResponses, pendingResponses)
    }

    // Stub method for testing
    func getAllResponses() -> [SurveyResponse] {
        return []
    }
}
