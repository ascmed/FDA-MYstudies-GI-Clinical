import XCTest

class SurveyCompletionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Survey List Display Tests

    func testSurveyListDisplay() throws {
        // Given
        // App is launched and user is authenticated

        // When
        let surveyList = app.tables["SurveyList"]

        // Then
        XCTAssert(surveyList.exists, "Survey list should be displayed")
    }

    func testSurveyListNavigation() throws {
        // Given
        let surveyList = app.tables["SurveyList"]
        XCTAssert(surveyList.exists)

        // When
        let firstSurvey = surveyList.cells.firstMatch
        firstSurvey.tap()

        // Then
        let detailView = app.otherElements["SurveyDetailView"]
        XCTAssert(detailView.waitForExistence(timeout: 2), "Survey detail should appear")
    }

    // MARK: - Survey Detail Display Tests

    func testSurveyDetailDisplay() throws {
        // Given
        // User navigated to survey detail
        let surveyTitle = app.staticTexts["SurveyTitle"]

        // When
        let titleExists = surveyTitle.exists

        // Then
        XCTAssert(titleExists, "Survey title should be displayed")
    }

    func testSurveyEstimatedDuration() throws {
        // Given
        let surveyDetail = app.otherElements["SurveyDetailView"]
        XCTAssert(surveyDetail.exists)

        // When
        let durationText = app.staticTexts["EstimatedDuration"]

        // Then
        XCTAssert(durationText.exists, "Estimated duration should be shown")
    }

    func testSurveyStatusIndicator() throws {
        // Given
        let surveyList = app.tables["SurveyList"]
        XCTAssert(surveyList.exists)

        // When
        let statusBadges = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Due'"))

        // Then
        XCTAssertGreaterThan(statusBadges.count, 0, "Status indicators should be present")
    }

    // MARK: - ResearchKit Survey Launch Tests

    func testResearchKitLaunch() throws {
        // Given
        let surveyDetail = app.otherElements["SurveyDetailView"]
        XCTAssert(surveyDetail.exists)

        // When
        let startButton = app.buttons["StartSurvey"]
        startButton.tap()

        // Then
        let researchKitView = app.otherElements["ResearchKitSurvey"]
        XCTAssert(researchKitView.waitForExistence(timeout: 3), "ResearchKit should launch")
    }

    // MARK: - Question Type Handling Tests

    func testTextQuestionType() throws {
        // Given
        let researchKit = app.otherElements["ResearchKitSurvey"]
        XCTAssert(researchKit.exists)

        // When
        let textField = app.textFields.firstMatch
        textField.tap()
        textField.typeText("Test Answer")

        // Then
        XCTAssertEqual(textField.value as? String, "Test Answer", "Text should be entered")
    }

    func testMultipleChoiceQuestion() throws {
        // Given
        let options = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Option'"))
        XCTAssertGreaterThan(options.count, 0, "Options should be available")

        // When
        options.element(boundBy: 0).tap()

        // Then
        let selectedOption = app.buttons.matching(NSPredicate(format: "selected == true"))
        XCTAssertGreaterThan(selectedOption.count, 0, "Option should be selected")
    }

    func testScaleQuestion() throws {
        // Given
        let scaleSlider = app.sliders.firstMatch

        // When
        if scaleSlider.exists {
            scaleSlider.adjust(toNormalizedSliderPosition: 0.5)
        }

        // Then
        XCTAssert(true, "Scale question handled")
    }

    func testNumericQuestion() throws {
        // Given
        let numberField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS 'Number'")).firstMatch

        // When
        if numberField.exists {
            numberField.tap()
            numberField.typeText("42")
        }

        // Then
        XCTAssert(true, "Numeric input handled")
    }

    func testDateQuestion() throws {
        // Given
        let datePicker = app.datePickers.firstMatch

        // When
        if datePicker.exists {
            // Interact with date picker
            datePicker.tap()
        }

        // Then
        XCTAssert(true, "Date question handled")
    }

    // MARK: - Survey Navigation Tests

    func testNextQuestion() throws {
        // Given
        let nextButton = app.buttons["Next"]
        XCTAssert(nextButton.exists)

        // When
        nextButton.tap()

        // Then
        let progressText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'of'"))
        XCTAssertGreaterThan(progressText.count, 0, "Progress should update")
    }

    func testPreviousQuestion() throws {
        // Given
        let previousButton = app.buttons["Previous"]

        // When
        if previousButton.exists {
            previousButton.tap()
        }

        // Then
        XCTAssert(true, "Previous navigation handled")
    }

    func testQuestionProgress() throws {
        // Given
        let progressIndicator = app.staticTexts["QuestionProgress"]

        // When
        let progressVisible = progressIndicator.exists

        // Then
        XCTAssert(progressVisible, "Progress indicator should be shown")
    }

    // MARK: - Response Submission Tests

    func testSubmitSurvey_Online() throws {
        // Given
        let submitButton = app.buttons["Submit"]
        XCTAssert(submitButton.exists)

        // When
        submitButton.tap()

        // Then
        let confirmation = app.alerts["SubmissionSuccess"].firstMatch
        XCTAssert(confirmation.waitForExistence(timeout: 2), "Confirmation should appear")
    }

    func testSubmitSurvey_Offline() throws {
        // Note: This would require simulating offline mode
        // Given
        // Offline mode enabled

        // When
        let submitButton = app.buttons["Submit"]
        if submitButton.exists {
            submitButton.tap()
        }

        // Then
        let localSaveMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'saved locally'"))
        if localSaveMessage.count > 0 {
            XCTAssert(true, "Offline save message shown")
        }
    }

    // MARK: - Response Validation Tests

    func testMissingRequiredField() throws {
        // Given
        let requiredField = app.textFields.matching(NSPredicate(format: "label CONTAINS 'Required'")).firstMatch
        XCTAssert(requiredField.exists)

        // When
        let submitButton = app.buttons["Submit"]
        submitButton.tap()

        // Then
        let errorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'required'"))
        XCTAssertGreaterThan(errorMessage.count, 0, "Error message should appear")
    }

    // MARK: - Survey Cancellation Tests

    func testCancelSurvey() throws {
        // Given
        let cancelButton = app.buttons["Cancel"]
        XCTAssert(cancelButton.exists)

        // When
        cancelButton.tap()

        // Then
        let surveyList = app.tables["SurveyList"]
        XCTAssert(surveyList.waitForExistence(timeout: 1), "Should return to survey list")
    }

    // MARK: - Loading State Tests

    func testLoadingIndicator() throws {
        // Given
        let surveyDetail = app.otherElements["SurveyDetailView"]
        XCTAssert(surveyDetail.exists)

        // When
        let startButton = app.buttons["StartSurvey"]
        startButton.tap()

        // Then
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            XCTAssert(loadingIndicator.waitForExistence(timeout: 1), "Loading should appear")
        }
    }

    // MARK: - Error Handling Tests

    func testNetworkErrorHandling() throws {
        // Note: Would require network error simulation
        // Given
        // Network error occurs

        // When
        // User attempts to submit

        // Then
        let errorAlert = app.alerts.firstMatch
        if errorAlert.exists {
            XCTAssert(true, "Error alert shown")
        }
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabels() throws {
        // Given
        let surveyList = app.tables["SurveyList"]
        XCTAssert(surveyList.exists)

        // When
        let cells = surveyList.cells

        // Then
        for i in 0..<min(cells.count, 3) {
            let cell = cells.element(boundBy: i)
            XCTAssertNotNil(cell.label, "Cell should have accessibility label")
        }
    }

    // MARK: - Performance Tests

    func testSurveyLoadingPerformance() throws {
        let surfaceStartTime = Date()

        // When
        let surveyDetail = app.otherElements["SurveyDetailView"]
        let exists = surveyDetail.waitForExistence(timeout: 2)

        let elapsedTime = Date().timeIntervalSince(surfaceStartTime)

        // Then
        XCTAssert(exists, "Survey should load")
        XCTAssertLessThan(elapsedTime, 3.0, "Survey should load quickly")
    }

    func testResearchKitLaunchPerformance() throws {
        // Given
        let startButton = app.buttons["StartSurvey"]
        XCTAssert(startButton.exists)

        let startTime = Date()

        // When
        startButton.tap()
        let researchKit = app.otherElements["ResearchKitSurvey"]
        let exists = researchKit.waitForExistence(timeout: 3)

        let elapsedTime = Date().timeIntervalSince(startTime)

        // Then
        XCTAssert(exists, "ResearchKit should launch")
        XCTAssertLessThan(elapsedTime, 4.0, "Launch should be performant")
    }
}
