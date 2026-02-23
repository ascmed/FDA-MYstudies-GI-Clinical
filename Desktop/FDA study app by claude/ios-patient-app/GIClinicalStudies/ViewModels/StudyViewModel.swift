import SwiftUI
import Combine

// MARK: - Study ViewModel
class StudyViewModel: ObservableObject {
    @Published var studies: [Study] = []
    @Published var upcomingSurveys: [Survey] = []
    @Published var studyMetrics: StudyMetrics?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private let storageService = StorageService.shared

    init() {
        loadCachedStudies()
    }

    // MARK: - Public Methods

    func fetchStudies() {
        isLoading = true
        errorMessage = nil

        apiService.getStudies()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                case .finished:
                    break
                }
            } receiveValue: { [weak self] studies in
                self?.studies = studies
                self?.storageService.saveStudies(studies)
                self?.fetchUpcomingSurveys()
                self?.calculateMetrics()
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }

    func getStudyDetails(_ studyId: String) -> AnyPublisher<StudyDetails, AppError> {
        apiService.getStudyDetails(studyId)
    }

    func fetchUpcomingSurveys() {
        var allSurveys: [Survey] = []

        for study in studies {
            apiService.getSurveys(forStudy: study.id)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    case .finished:
                        break
                    }
                } receiveValue: { [weak self] surveys in
                    allSurveys.append(contentsOf: surveys)
                    self?.upcomingSurveys = allSurveys.sorted { survey1, survey2 in
                        guard let date1 = survey1.nextScheduledDate,
                              let date2 = survey2.nextScheduledDate else {
                            return false
                        }
                        return date1 < date2
                    }
                }
                .store(in: &self.cancellables)
        }
    }

    func calculateMetrics() {
        guard let firstStudy = studies.first else { return }

        // Calculate aggregate metrics from all studies
        let totalCompletion = studies.map { $0.completionPercentage }.reduce(0, +) / Double(max(1, studies.count))

        let daysRemaining = firstStudy.durationWeeks * 7 - Int(firstStudy.completionPercentage)

        studyMetrics = StudyMetrics(
            completionPercentage: totalCompletion,
            surveysCompleted: Int(totalCompletion / 10), // Simplified
            totalSurveys: firstStudy.durationWeeks,
            daysRemaining: daysRemaining,
            lastActivityDate: Date()
        )
    }

    // MARK: - Private Methods

    private func loadCachedStudies() {
        let cached = storageService.getStudies()
        if !cached.isEmpty {
            studies = cached
            calculateMetrics()
        }
    }
}
