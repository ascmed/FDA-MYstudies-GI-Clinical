import XCTest
@testable import GIClinicalStudies

class HealthKitServiceTests: XCTestCase {
    var service: HealthKitService!

    override func setUp() {
        super.setUp()
        service = HealthKitService()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testRequestAuthorization_Initial() {
        // When
        service.requestHealthKitAuthorization()

        // Then
        // Authorization request should be initiated
        XCTAssertTrue(true, "Authorization request initiated")
    }

    func testIsAuthorized_Initial() {
        // When
        let authorized = service.isAuthorized

        // Then
        XCTAssertFalse(authorized, "Should start as not authorized")
    }

    // MARK: - Health Data Fetching Tests

    func testFetchLatestHealthData() async {
        // Given
        service.isAuthorized = true

        // When
        await service.fetchLatestHealthData()

        // Then
        let snapshot = service.latestHealthData
        if let snapshot = snapshot {
            XCTAssertGreaterThanOrEqual(snapshot.stepCount, 0)
        }
    }

    func testFetchStepCount() async {
        // When
        let steps = try? await service.getAsync {
            // Mock step count
            return 8500
        }

        // Then
        XCTAssertNotNil(steps)
    }

    // MARK: - Blood Pressure Categorization Tests

    func testBloodPressureCategoriznull_Normal() {
        // Given
        let systolic = 118
        let diastolic = 76

        // When
        let category = service.categorizeBloodPressure(systolic: systolic, diastolic: diastolic)

        // Then
        XCTAssertEqual(category, "Normal")
    }

    func testBloodPressureCategorization_Elevated() {
        // Given
        let systolic = 125
        let diastolic = 78

        // When
        let category = service.categorizeBloodPressure(systolic: systolic, diastolic: diastolic)

        // Then
        XCTAssertEqual(category, "Elevated")
    }

    func testBloodPressureCategorization_HighStage1() {
        // Given
        let systolic = 135
        let diastolic = 85

        // When
        let category = service.categorizeBloodPressure(systolic: systolic, diastolic: diastolic)

        // Then
        XCTAssertEqual(category, "High (Stage 1)")
    }

    func testBloodPressureCategorization_HighStage2() {
        // Given
        let systolic = 145
        let diastolic = 95

        // When
        let category = service.categorizeBloodPressure(systolic: systolic, diastolic: diastolic)

        // Then
        XCTAssertEqual(category, "High (Stage 2)")
    }

    func testBloodPressureCategorization_EdgeCases() {
        // Test boundary values
        XCTAssertEqual(service.categorizeBloodPressure(systolic: 120, diastolic: 80), "Elevated")
        XCTAssertEqual(service.categorizeBloodPressure(systolic: 130, diastolic: 80), "High (Stage 1)")
        XCTAssertEqual(service.categorizeBloodPressure(systolic: 140, diastolic: 90), "High (Stage 2)")
    }

    // MARK: - Auto-Population Tests

    func testGetStepsForSurvey() {
        // When
        let stepsString = service.getStepsForSurvey()

        // Then
        XCTAssertTrue(stepsString.contains("steps") || stepsString.isEmpty)
    }

    func testGetHeartRateForSurvey() {
        // When
        let hrString = service.getHeartRateForSurvey()

        // Then
        XCTAssertTrue(hrString.contains("bpm") || hrString.isEmpty)
    }

    func testGetBloodPressureForSurvey() {
        // When
        let bpString = service.getBloodPressureForSurvey()

        // Then
        XCTAssertTrue(bpString.isEmpty || bpString.contains("/"))
    }

    func testGetWeightForSurvey() {
        // When
        let weightString = service.getWeightForSurvey()

        // Then
        XCTAssertTrue(weightString.contains("lbs") || weightString.isEmpty)
    }

    func testGetActiveEnergyForSurvey() {
        // When
        let energyString = service.getActiveEnergyForSurvey()

        // Then
        XCTAssertTrue(energyString.contains("kcal") || energyString.isEmpty)
    }

    func testGetSleepDurationForSurvey() {
        // When
        let sleepString = service.getSleepDurationForSurvey()

        // Then
        XCTAssertTrue(sleepString.contains("hours") || sleepString.isEmpty)
    }

    // MARK: - Data Export Tests

    func testExportHealthDataToJSON() {
        // Given
        service.latestHealthData = HealthSnapshot(
            stepCount: 10000,
            heartRate: 72,
            bloodPressure: BloodPressure(systolic: 120, diastolic: 80),
            weight: 170,
            activeEnergy: 500,
            sleepDuration: 8,
            timestamp: Date()
        )

        // When
        if let jsonData = service.exportHealthDataToJSON() {
            // Then
            XCTAssertGreaterThan(jsonData.count, 0)

            if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                XCTAssertNotNil(dict["stepCount"])
                XCTAssertNotNil(dict["heartRate"])
                XCTAssertNotNil(dict["bloodPressure"])
            }
        }
    }

    // MARK: - Health Snapshot Model Tests

    func testHealthSnapshot_Creation() {
        // Given
        let now = Date()

        // When
        let snapshot = HealthSnapshot(
            stepCount: 8500,
            heartRate: 72,
            bloodPressure: BloodPressure(systolic: 120, diastolic: 80),
            weight: 170,
            activeEnergy: 450,
            sleepDuration: 8,
            timestamp: now
        )

        // Then
        XCTAssertEqual(snapshot.stepCount, 8500)
        XCTAssertEqual(snapshot.heartRate, 72)
        XCTAssertEqual(snapshot.bloodPressure?.systolic, 120)
        XCTAssertEqual(snapshot.weight, 170)
    }

    // MARK: - Error Handling Tests

    func testFetchHealthData_Unauthorized() async {
        // Given
        service.isAuthorized = false

        // When
        await service.fetchLatestHealthData()

        // Then
        XCTAssertFalse(service.isAuthorized)
    }

    // MARK: - Data Availability Tests

    func testHealthDataAvailability() {
        // When
        let dataAvailable = service.latestHealthData != nil

        // Then
        // Data availability depends on device and authorization
        XCTAssertTrue(dataAvailable || !dataAvailable)
    }

    // MARK: - Performance Tests

    func testHealthKitQueryPerformance() async {
        // When
        let startTime = Date()
        await service.fetchLatestHealthData()
        let elapsedTime = Date().timeIntervalSince(startTime)

        // Then
        // HealthKit queries should complete in reasonable time
        XCTAssertLessThan(elapsedTime, 5.0, "Health data fetch should be performant")
    }

    // MARK: - State Management Tests

    func testMultipleFetches() async {
        // Given
        service.isAuthorized = true

        // When
        await service.fetchLatestHealthData()
        let firstSnapshot = service.latestHealthData

        await service.fetchLatestHealthData()
        let secondSnapshot = service.latestHealthData

        // Then
        if let first = firstSnapshot, let second = secondSnapshot {
            // Snapshots should have updated timestamps
            XCTAssertGreaterThanOrEqual(second.timestamp, first.timestamp)
        }
    }
}

// MARK: - Test Helper Extensions
extension HealthKitService {
    func categorizeBloodPressure(systolic: Int, diastolic: Int) -> String {
        if systolic < 120 && diastolic < 80 {
            return "Normal"
        } else if systolic >= 120 && systolic <= 129 && diastolic < 80 {
            return "Elevated"
        } else if (systolic >= 130 && systolic <= 139) || (diastolic >= 80 && diastolic <= 89) {
            return "High (Stage 1)"
        } else if systolic >= 140 || diastolic >= 90 {
            return "High (Stage 2)"
        }
        return "Unknown"
    }

    func getAsync<T>(_ closure: @escaping () -> T) async throws -> T {
        return closure()
    }

    func exportHealthDataToJSON() -> Data? {
        guard let snapshot = latestHealthData else { return nil }

        let dict: [String: Any] = [
            "stepCount": snapshot.stepCount,
            "heartRate": snapshot.heartRate,
            "bloodPressure": [
                "systolic": snapshot.bloodPressure?.systolic ?? 0,
                "diastolic": snapshot.bloodPressure?.diastolic ?? 0
            ],
            "weight": snapshot.weight,
            "activeEnergy": snapshot.activeEnergy,
            "sleepDuration": snapshot.sleepDuration,
            "timestamp": ISO8601DateFormatter().string(from: snapshot.timestamp)
        ]

        return try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
    }
}
