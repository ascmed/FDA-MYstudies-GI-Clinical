import Foundation
import Combine

// MARK: - Survey View Model
class SurveyViewModel: ObservableObject {
    @Published var survey: Survey?
    @Published var questions: [Question] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var saveProgress: Double = 0.0

    private let apiService = APIService.shared
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Load Survey Details
    func loadSurveyDetails(survey: Survey) {
        isLoading = true
        errorMessage = nil

        // Try to load from cache first
        if let cachedQuestions = survey.questions {
            self.survey = survey
            self.questions = cachedQuestions
            isLoading = false
            return
        }

        // Load from API if not cached
        Task { @MainActor in
            do {
                let questions = try await apiService.getSurveyQuestions(surveyId: survey.id)
                self.survey = survey
                self.questions = questions

                // Cache locally
                try storageService.saveSurveyQuestions(questions, for: survey.id)

                isLoading = false
            } catch {
                errorMessage = "Failed to load survey questions: \(error.localizedDescription)"
                isLoading = false
                Logger.error("Failed to load survey questions: \(error)")
            }
        }
    }

    // MARK: - Save Survey Response
    func saveSurveyResponse(_ response: SurveyResponse) {
        isSaving = true
        errorMessage = nil

        Task { @MainActor in
            do {
                // Save locally first
                try storageService.saveSurveyResponse(response)

                // Try to sync with backend
                do {
                    try await apiService.submitSurveyResponse(response)
                    Logger.log("Survey response submitted successfully")
                } catch {
                    // If sync fails, mark as pending sync
                    Logger.warning("Survey response saved locally, sync pending: \(error)")
                }

                isSaving = false
                saveProgress = 1.0
            } catch {
                errorMessage = "Failed to save survey response: \(error.localizedDescription)"
                isSaving = false
                Logger.error("Failed to save survey response: \(error)")
            }
        }
    }

    // MARK: - Get Upcoming Surveys
    func getUpcomingSurveys() -> [Survey] {
        do {
            let surveys = try storageService.getUpcomingSurveys()
            return surveys.sorted { ($0.nextScheduledDate ?? Date.distantFuture) < ($1.nextScheduledDate ?? Date.distantFuture) }
        } catch {
            Logger.error("Failed to get upcoming surveys: \(error)")
            return []
        }
    }

    // MARK: - Mark Survey as Completed
    func markSurveyCompleted(surveyId: String) {
        Task { @MainActor in
            do {
                try await apiService.markSurveyCompleted(surveyId: surveyId)
                Logger.log("Survey marked as completed: \(surveyId)")
            } catch {
                Logger.error("Failed to mark survey completed: \(error)")
            }
        }
    }

    // MARK: - Get Survey Statistics
    func getSurveyStats() -> SurveyStats {
        do {
            let allSurveys = try storageService.getAllSurveys()
            let completedCount = allSurveys.filter { $0.lastCompletedDate != nil }.count
            let overdueCount = allSurveys.filter { $0.isOverdue }.count
            let upcomingCount = allSurveys.filter { !$0.isOverdue && $0.nextScheduledDate != nil }.count

            return SurveyStats(
                totalSurveys: allSurveys.count,
                completedSurveys: completedCount,
                overdueSurveys: overdueCount,
                upcomingSurveys: upcomingCount
            )
        } catch {
            Logger.error("Failed to get survey stats: \(error)")
            return SurveyStats(totalSurveys: 0, completedSurveys: 0, overdueSurveys: 0, upcomingSurveys: 0)
        }
    }

    // MARK: - Get Survey by ID
    func getSurvey(id: String) -> Survey? {
        do {
            return try storageService.getSurvey(id: id)
        } catch {
            Logger.error("Failed to get survey: \(error)")
            return nil
        }
    }

    // MARK: - Delete Survey Response (for unsync'd responses)
    func deleteSurveyResponse(responseId: String) {
        do {
            try storageService.deleteSurveyResponse(responseId: responseId)
            Logger.log("Survey response deleted: \(responseId)")
        } catch {
            Logger.error("Failed to delete survey response: \(error)")
        }
    }

    // MARK: - Get Pending Responses (for offline sync)
    func getPendingResponses() -> [SurveyResponse] {
        do {
            return try storageService.getPendingSurveyResponses()
        } catch {
            Logger.error("Failed to get pending responses: \(error)")
            return []
        }
    }

    // MARK: - Sync Pending Responses
    func syncPendingResponses() {
        let pendingResponses = getPendingResponses()

        guard !pendingResponses.isEmpty else {
            Logger.log("No pending responses to sync")
            return
        }

        isSaving = true
        let totalCount = pendingResponses.count

        for (index, response) in pendingResponses.enumerated() {
            Task { @MainActor in
                do {
                    try await apiService.submitSurveyResponse(response)
                    try storageService.markResponseAsSynced(responseId: response.id)

                    // Update progress
                    saveProgress = Double(index + 1) / Double(totalCount)

                    if index == totalCount - 1 {
                        isSaving = false
                        Logger.log("All pending responses synced successfully")
                    }
                } catch {
                    Logger.error("Failed to sync response \(response.id): \(error)")
                }
            }
        }
    }
}

// MARK: - Survey Stats Model
struct SurveyStats {
    let totalSurveys: Int
    let completedSurveys: Int
    let overdueSurveys: Int
    let upcomingSurveys: Int

    var completionPercentage: Double {
        guard totalSurveys > 0 else { return 0 }
        return Double(completedSurveys) / Double(totalSurveys) * 100
    }

    var onTrackStatus: String {
        if overdueSurveys > 0 {
            return "Behind Schedule"
        } else if upcomingSurveys > 0 {
            return "On Track"
        } else {
            return "All Surveys Complete"
        }
    }
}
