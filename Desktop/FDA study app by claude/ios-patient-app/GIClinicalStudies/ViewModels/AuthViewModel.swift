import SwiftUI
import Combine

// MARK: - Auth ViewModel
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let storageService = StorageService.shared
    private let apiService = APIService.shared

    init() {
        setupInitialState()
    }

    // MARK: - Public Methods

    func enrollWithToken(_ token: String) {
        isLoading = true
        errorMessage = nil

        apiService.enrollWithToken(token)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                self?.handleAuthResponse(response)
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }

    func logout() {
        isAuthenticated = false
        currentUser = nil
        apiService.clearAuthToken()
        storageService.clearAuthToken()
        storageService.clearUser()
    }

    func updatePushToken(_ token: String) {
        apiService.registerPushToken(token)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    Logger.error("Failed to register push token: \(error)")
                case .finished:
                    Logger.log("Push token registered successfully")
                }
            } receiveValue: { _ in
                //
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func setupInitialState() {
        if let savedToken = storageService.getAuthToken(),
           let savedUser = storageService.getUser() {
            apiService.setAuthToken(savedToken)
            currentUser = savedUser
            isAuthenticated = true
        }

        hasCompletedOnboarding = storageService.hasCompletedOnboarding()
    }

    private func handleAuthResponse(_ response: AuthResponse) {
        let user = response.user
        let token = response.token

        // Save to storage
        storageService.saveAuthToken(token)
        storageService.saveUser(user)
        storageService.setOnboardingCompleted(true)

        // Update API service
        apiService.setAuthToken(token)

        // Update UI
        currentUser = user
        isAuthenticated = true
        hasCompletedOnboarding = true
    }
}
