import Foundation
import Combine
import Network

// MARK: - Sync Engine
class SyncEngine: NSObject, ObservableObject {
    static let shared = SyncEngine()

    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncTime: Date?
    @Published var pendingCount: Int = 0
    @Published var failedCount: Int = 0
    @Published var isOnline = true
    @Published var syncError: String?

    private let apiService = APIService.shared
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.giclinicalstudies.networkmonitor")
    private let syncQueue = DispatchQueue(label: "com.giclinicalstudies.sync", attributes: .concurrent)

    // Retry configuration
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 1.0
    private var retryCount: [String: Int] = [:]

    override init() {
        super.init()
        setupNetworkMonitoring()
        setupSyncTriggers()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOnline = self?.isOnline ?? false
                self?.isOnline = path.status == .satisfied

                // If came back online, trigger sync
                if !wasOnline && self?.isOnline == true {
                    Logger.log("Network restored - triggering sync")
                    self?.performSync()
                }
            }
        }

        monitor.start(queue: monitorQueue)
    }

    private func setupSyncTriggers() {
        // Observe app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                Logger.log("App backgrounding - initiating sync")
                self?.performSync()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                // Check if we need to sync
                if let lastSync = self?.lastSyncTime,
                   Date().timeIntervalSince(lastSync) > 300 {
                    // More than 5 minutes since last sync
                    self?.performSync()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Sync Operations

    func performSync() {
        guard isOnline && !isSyncing else {
            Logger.log("Sync skipped - online: \(isOnline), already syncing: \(isSyncing)")
            return
        }

        Task { @MainActor in
            isSyncing = true
            syncError = nil
            syncProgress = 0.0

            do {
                // Sync survey responses
                try await syncSurveyResponses()

                // Sync consent data
                try await syncConsentData()

                // Update pending count
                updatePendingCount()

                lastSyncTime = Date()
                isSyncing = false
                syncProgress = 1.0

                Logger.log("Sync completed successfully")
            } catch {
                syncError = error.localizedDescription
                isSyncing = false
                Logger.error("Sync failed: \(error)")
            }
        }
    }

    // MARK: - Survey Response Sync

    private func syncSurveyResponses() async throws {
        let pendingResponses = storageService.getPendingSurveyResponses()

        guard !pendingResponses.isEmpty else {
            Logger.log("No pending survey responses to sync")
            return
        }

        Logger.log("Syncing \(pendingResponses.count) survey responses")

        var successCount = 0
        let totalCount = pendingResponses.count

        for response in pendingResponses {
            do {
                try await syncSurveyResponse(response)
                successCount += 1

                // Update progress
                await MainActor.run {
                    syncProgress = Double(successCount) / Double(totalCount)
                }
            } catch {
                Logger.error("Failed to sync response \(response.id): \(error)")
                await handleSyncFailure(for: response.id)
            }
        }

        Logger.log("Survey response sync complete: \(successCount)/\(totalCount) succeeded")
    }

    private func syncSurveyResponse(_ response: SurveyResponse) async throws {
        let responseId = response.id

        // Check retry count
        let retries = retryCount[responseId] ?? 0
        guard retries < maxRetries else {
            throw SyncError.maxRetriesExceeded
        }

        do {
            try await apiService.submitSurveyResponse(response)
            try storageService.markResponseAsSynced(responseId: responseId)
            retryCount.removeValue(forKey: responseId)

            Logger.log("Synced survey response: \(responseId)")
        } catch {
            retryCount[responseId] = retries + 1
            throw error
        }
    }

    // MARK: - Consent Data Sync

    private func syncConsentData() async throws {
        // Sync pending consent records
        Logger.log("Syncing consent data")

        // This would sync any pending consent operations
        // For now, consent is submitted immediately in Phase 2B
        // In future phases, could queue consent operations if needed
    }

    // MARK: - Sync Failure Handling

    private func handleSyncFailure(for itemId: String) {
        let retries = retryCount[itemId] ?? 0
        let retryDelay = baseRetryDelay * pow(2, Double(retries))

        Logger.log("Scheduling retry for \(itemId) in \(retryDelay) seconds (attempt \(retries + 1)/\(maxRetries))")

        DispatchQueue.global().asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            guard self?.isOnline == true else {
                Logger.log("Offline - skipping retry for \(itemId)")
                return
            }

            // Retry is handled in next full sync
        }
    }

    // MARK: - Pending Count Management

    private func updatePendingCount() {
        let pending = storageService.getPendingSurveyResponses()
        pendingCount = pending.count
        failedCount = retryCount.filter { $0.value >= maxRetries }.count
    }

    // MARK: - Conflict Resolution

    func resolveConflict(for itemId: String, strategy: ConflictResolutionStrategy) async throws {
        switch strategy {
        case .keepLocal:
            Logger.log("Keeping local version for \(itemId)")
            // Local version is retained

        case .keepRemote:
            Logger.log("Discarding local version for \(itemId)")
            // Remove local version, re-fetch from server
            try storageService.deleteSurveyResponse(responseId: itemId)

        case .merge(let mergedData):
            Logger.log("Merging versions for \(itemId)")
            // Merge local and remote data
            // Implementation depends on data structure
        }
    }

    // MARK: - Manual Sync Trigger

    func manualSync() {
        Logger.log("Manual sync triggered")
        performSync()
    }

    // MARK: - Sync Status

    func getSyncStatus() -> SyncStatus {
        return SyncStatus(
            isOnline: isOnline,
            isSyncing: isSyncing,
            pendingCount: pendingCount,
            failedCount: failedCount,
            lastSyncTime: lastSyncTime,
            syncProgress: syncProgress
        )
    }

    // MARK: - Queue Management

    func clearSyncQueue() {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.retryCount.removeAll()
            Logger.log("Sync queue cleared")
        }
    }

    func getSyncQueueSize() -> Int {
        let pending = storageService.getPendingSurveyResponses()
        return pending.count
    }

    // MARK: - Background Sync Configuration

    func configureBGSync(with minInterval: TimeInterval = 300) {
        // Configure for background app refresh
        // Minimum interval between background syncs (in seconds)
        Logger.log("BG sync configured with \(minInterval)s minimum interval")

        // Note: Actual background app refresh configuration happens in app delegate
        // This is a helper to set preferences
    }

    // MARK: - Cleanup

    func cleanup() {
        monitor.cancel()
        cancellables.removeAll()
    }

    deinit {
        cleanup()
    }
}

// MARK: - Sync Status Model
struct SyncStatus {
    let isOnline: Bool
    let isSyncing: Bool
    let pendingCount: Int
    let failedCount: Int
    let lastSyncTime: Date?
    let syncProgress: Double

    var statusMessage: String {
        if isSyncing {
            return "Syncing... \(Int(syncProgress * 100))%"
        } else if !isOnline {
            return "Offline - \(pendingCount) pending"
        } else if pendingCount > 0 {
            return "\(pendingCount) pending"
        } else if let lastSync = lastSyncTime {
            let timeAgo = Date().timeIntervalSince(lastSync)
            if timeAgo < 60 {
                return "Synced just now"
            } else if timeAgo < 3600 {
                let minutes = Int(timeAgo / 60)
                return "Synced \(minutes)m ago"
            } else {
                let hours = Int(timeAgo / 3600)
                return "Synced \(hours)h ago"
            }
        } else {
            return "Never synced"
        }
    }

    var syncStatusColor: String {
        if !isOnline {
            return "red"
        } else if pendingCount > 0 {
            return "yellow"
        } else {
            return "green"
        }
    }
}

// MARK: - Conflict Resolution Strategy
enum ConflictResolutionStrategy {
    case keepLocal
    case keepRemote
    case merge(data: [String: AnyCodable])
}

// MARK: - Sync Error
enum SyncError: LocalizedError {
    case networkError(String)
    case maxRetriesExceeded
    case conflictDetected
    case encryptionFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .maxRetriesExceeded:
            return "Max retries exceeded - item will retry later"
        case .conflictDetected:
            return "Conflict detected - manual resolution needed"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decodingFailed:
            return "Failed to decode synced data"
        }
    }
}

// MARK: - Sync Queue Item
struct SyncQueueItem: Codable {
    let id: String
    let itemType: SyncItemType
    let data: Data
    let createdAt: Date
    let retryCount: Int
    let priority: SyncPriority

    enum CodingKeys: String, CodingKey {
        case id
        case itemType = "item_type"
        case data
        case createdAt = "created_at"
        case retryCount = "retry_count"
        case priority
    }
}

// MARK: - Sync Item Type
enum SyncItemType: String, Codable {
    case surveyResponse = "survey_response"
    case consentData = "consent_data"
    case profileUpdate = "profile_update"
    case healthData = "health_data"
}

// MARK: - Sync Priority
enum SyncPriority: Int, Codable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
}
