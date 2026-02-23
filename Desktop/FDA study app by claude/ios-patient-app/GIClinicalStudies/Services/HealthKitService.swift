import Foundation
import HealthKit

// MARK: - HealthKit Service
class HealthKitService: NSObject, ObservableObject {
    static let shared = HealthKitService()

    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var latestHealthData: HealthSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let healthStore = HKHealthStore()
    private var healthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    override init() {
        super.init()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestHealthKitAuthorization() {
        guard healthKitAvailable else {
            errorMessage = "HealthKit is not available on this device"
            Logger.warning("HealthKit not available")
            return
        }

        let readTypes = getReadTypes()

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
                    Logger.error("HealthKit auth failed: \(error)")
                } else {
                    self?.checkAuthorizationStatus()
                    Logger.log("HealthKit authorization granted")
                }
            }
        }
    }

    private func checkAuthorizationStatus() {
        guard healthKitAvailable else { return }

        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            let status = healthStore.authorizationStatus(for: stepType)
            authorizationStatus = status
            isAuthorized = status == .sharingAuthorized
        }
    }

    private func getReadTypes() -> Set<HKObjectType> {
        var readTypes: Set<HKObjectType> = []

        // Steps
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            readTypes.insert(stepType)
        }

        // Heart Rate
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            readTypes.insert(heartRateType)
        }

        // Blood Pressure
        if let bpSystolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
            readTypes.insert(bpSystolicType)
        }
        if let bpDiastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            readTypes.insert(bpDiastolicType)
        }

        // Weight
        if let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            readTypes.insert(weightType)
        }

        // Active Energy
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            readTypes.insert(activeEnergyType)
        }

        // Sleep
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            readTypes.insert(sleepType)
        }

        return readTypes
    }

    // MARK: - Fetch Health Data

    func fetchLatestHealthData() {
        guard isAuthorized else {
            Logger.warning("HealthKit not authorized")
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let snapshot = HealthSnapshot()

                // Fetch all metrics
                snapshot.stepCount = try await fetchStepCount()
                snapshot.heartRate = try await fetchHeartRate()
                snapshot.bloodPressure = try await fetchBloodPressure()
                snapshot.weight = try await fetchWeight()
                snapshot.activeEnergy = try await fetchActiveEnergy()
                snapshot.sleepDuration = try await fetchSleepDuration()

                await MainActor.run {
                    self.latestHealthData = snapshot
                    self.isLoading = false
                    Logger.log("Health data fetched successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch health data: \(error.localizedDescription)"
                    self.isLoading = false
                    Logger.error("Failed to fetch health data: \(error)")
                }
            }
        }
    }

    // MARK: - Individual Metric Fetching

    private func fetchStepCount() async throws -> Int {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        let today = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: today, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = result?.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchHeartRate() async throws -> Int {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return 0
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, results, error in
            // Results handled in continuation
        }

        return try await withCheckedThrowingContinuation { continuation in
            let queryWithHandler = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = results?.first as? HKQuantitySample {
                    let bpm = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                    continuation.resume(returning: bpm)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(queryWithHandler)
        }
    }

    private func fetchBloodPressure() async throws -> BloodPressure? {
        guard let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        // Fetch systolic
        let systolic = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: systolicType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = results?.first as? HKQuantitySample {
                    let value = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }

        // Fetch diastolic
        let diastolic = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: diastolicType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = results?.first as? HKQuantitySample {
                    let value = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }

        return BloodPressure(systolic: systolic, diastolic: diastolic)
    }

    private func fetchWeight() async throws -> Double {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return 0
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = results?.first as? HKQuantitySample {
                    let weight = sample.quantity.doubleValue(for: HKUnit.pound())
                    continuation.resume(returning: weight)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchActiveEnergy() async throws -> Int {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        let today = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: today, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = result?.sumQuantity() {
                    let calories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
                    continuation.resume(returning: calories)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchSleepDuration() async throws -> Int {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return 0
        }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let duration = (results as? [HKCategorySample])?.reduce(0) { sum, sample in
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        return sum + Int(duration / 3600) // Convert to hours
                    } ?? 0
                    continuation.resume(returning: duration)
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Auto-Population Helpers

    func getStepsForSurvey() -> String {
        guard let steps = latestHealthData?.stepCount else { return "" }
        return "\(steps)"
    }

    func getHeartRateForSurvey() -> String {
        guard let heartRate = latestHealthData?.heartRate else { return "" }
        return "\(heartRate) bpm"
    }

    func getWeightForSurvey() -> String {
        guard let weight = latestHealthData?.weight else { return "" }
        return String(format: "%.1f lbs", weight)
    }

    func getBloodPressureForSurvey() -> String {
        guard let bp = latestHealthData?.bloodPressure else { return "" }
        return "\(bp.systolic)/\(bp.diastolic) mmHg"
    }

    func getActiveEnergyForSurvey() -> String {
        guard let energy = latestHealthData?.activeEnergy else { return "" }
        return "\(energy) kcal"
    }

    func getSleepForSurvey() -> String {
        guard let sleep = latestHealthData?.sleepDuration else { return "" }
        return "\(sleep) hours"
    }

    // MARK: - Health Data Export

    func exportHealthDataAsJSON() -> String? {
        guard let healthData = latestHealthData else { return nil }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(healthData)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            Logger.error("Failed to encode health data: \(error)")
            return nil
        }
    }

    // MARK: - Health Data Tracking

    func startHealthDataTracking() {
        // Set up periodic health data updates
        Logger.log("Health data tracking started")
        fetchLatestHealthData()
    }

    func stopHealthDataTracking() {
        Logger.log("Health data tracking stopped")
    }
}

// MARK: - Health Snapshot
struct HealthSnapshot: Codable {
    var stepCount: Int = 0
    var heartRate: Int = 0
    var bloodPressure: BloodPressure?
    var weight: Double = 0
    var activeEnergy: Int = 0
    var sleepDuration: Int = 0
    var timestamp: Date = Date()

    var summary: String {
        var components: [String] = []

        if stepCount > 0 {
            components.append("\(stepCount) steps")
        }
        if heartRate > 0 {
            components.append("\(heartRate) bpm")
        }
        if let bp = bloodPressure {
            components.append("\(bp.systolic)/\(bp.diastolic) mmHg")
        }
        if weight > 0 {
            components.append(String(format: "%.1f lbs", weight))
        }
        if activeEnergy > 0 {
            components.append("\(activeEnergy) kcal")
        }
        if sleepDuration > 0 {
            components.append("\(sleepDuration)h sleep")
        }

        return components.joined(separator: ", ")
    }
}

// MARK: - Blood Pressure
struct BloodPressure: Codable {
    let systolic: Int
    let diastolic: Int

    var isNormal: Bool {
        systolic < 120 && diastolic < 80
    }

    var isElevated: Bool {
        (systolic >= 120 && systolic < 130) && diastolic < 80
    }

    var isHighStage1: Bool {
        (systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)
    }

    var isHighStage2: Bool {
        systolic >= 140 || diastolic >= 90
    }

    var category: String {
        switch true {
        case isNormal:
            return "Normal"
        case isElevated:
            return "Elevated"
        case isHighStage1:
            return "High (Stage 1)"
        case isHighStage2:
            return "High (Stage 2)"
        default:
            return "Unknown"
        }
    }
}
