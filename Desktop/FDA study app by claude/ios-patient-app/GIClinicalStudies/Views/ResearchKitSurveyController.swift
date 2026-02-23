import SwiftUI
import UIKit
import ResearchKit

// MARK: - ResearchKit Survey Controller
struct ResearchKitSurveyController: UIViewControllerRepresentable {
    let survey: Survey
    var onCompletion: (SurveyResponse) -> Void

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        // Build ResearchKit task from survey questions
        let steps = buildResearchKitSteps()
        let task = ORKOrderedTask(identifier: survey.id, steps: steps)

        let taskVC = ORKTaskViewController(task: task, taskRun: nil)
        taskVC.delegate = context.coordinator
        taskVC.view.tintColor = UIColor(Color.primaryGreen)

        return taskVC
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {
        // Update if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            survey: survey,
            onCompletion: onCompletion
        )
    }

    // MARK: - Build ResearchKit Steps
    private func buildResearchKitSteps() -> [ORKStep] {
        var steps: [ORKStep] = []

        // Add instruction step
        let instructionStep = ORKInstructionStep(identifier: "instruction")
        instructionStep.title = survey.title
        instructionStep.text = survey.description ?? "Please complete this survey"
        instructionStep.detailText = "Your responses are encrypted and secure. This survey takes approximately 5-10 minutes."
        steps.append(instructionStep)

        // Add question steps
        if let questions = survey.questions {
            for question in questions {
                if let step = questionToORKStep(question) {
                    steps.append(step)
                }
            }
        }

        // Add completion step
        let completionStep = ORKCompletionStep(identifier: "completion")
        completionStep.title = "Thank You"
        completionStep.text = "Your responses have been recorded securely."
        steps.append(completionStep)

        return steps
    }

    // MARK: - Convert Question to ORKStep
    private func questionToORKStep(_ question: Question) -> ORKStep? {
        switch question.questionType {
        case .text:
            return createTextStep(question)

        case .multipleChoice:
            return createMultipleChoiceStep(question)

        case .scale:
            return createScaleStep(question)

        case .numeric:
            return createNumericStep(question)

        case .date:
            return createDateStep(question)

        case .time:
            return createTimeStep(question)
        }
    }

    private func createTextStep(_ question: Question) -> ORKStep? {
        let answerFormat = ORKTextAnswerFormat(maximumLength: 500)
        answerFormat.multipleLines = true

        let step = ORKQuestionStep(identifier: question.id, title: nil, question: question.questionText, answer: answerFormat)
        step.isOptional = !question.isRequired

        if let helpText = question.helpText {
            step.text = helpText
        }

        return step
    }

    private func createMultipleChoiceStep(_ question: Question) -> ORKStep? {
        guard let choices = question.choices, !choices.isEmpty else {
            return nil
        }

        let textChoices = choices.map { choice in
            ORKTextChoice(text: choice.choiceText, value: choice.choiceValue ?? choice.id)
        }

        let answerFormat = ORKValuePickerAnswerFormat(textChoices: textChoices)
        let step = ORKQuestionStep(identifier: question.id, title: nil, question: question.questionText, answer: answerFormat)
        step.isOptional = !question.isRequired

        if let helpText = question.helpText {
            step.text = helpText
        }

        return step
    }

    private func createScaleStep(_ question: Question) -> ORKStep? {
        let answerFormat = ORKScaleAnswerFormat(
            maximumValue: 10,
            minimumValue: 1,
            defaultValue: 5,
            step: 1,
            vertical: false,
            maximumValueDescription: "Severe",
            minimumValueDescription: "Minimal"
        )

        let step = ORKQuestionStep(identifier: question.id, title: nil, question: question.questionText, answer: answerFormat)
        step.isOptional = !question.isRequired

        if let helpText = question.helpText {
            step.text = helpText
        }

        return step
    }

    private func createNumericStep(_ question: Question) -> ORKStep? {
        let answerFormat = ORKNumericAnswerFormat(style: .integer)
        let step = ORKQuestionStep(identifier: question.id, title: nil, question: question.questionText, answer: answerFormat)
        step.isOptional = !question.isRequired

        if let helpText = question.helpText {
            step.text = helpText
        }

        return step
    }

    private func createDateStep(_ question: Question) -> ORKStep? {
        let answerFormat = ORKDateAnswerFormat(style: .date)
        let step = ORKQuestionStep(identifier: question.id, title: nil, question: question.questionText, answer: answerFormat)
        step.isOptional = !question.isRequired

        if let helpText = question.helpText {
            step.text = helpText
        }

        return step
    }

    private func createTimeStep(_ question: Question) -> ORKStep? {
        let answerFormat = ORKTimeOfDayAnswerFormat()
        let step = ORKQuestionStep(identifier: question.id, title: nil, question: question.questionText, answer: answerFormat)
        step.isOptional = !question.isRequired

        if let helpText = question.helpText {
            step.text = helpText
        }

        return step
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let survey: Survey
        let onCompletion: (SurveyResponse) -> Void

        init(survey: Survey, onCompletion: @escaping (SurveyResponse) -> Void) {
            self.survey = survey
            self.onCompletion = onCompletion
        }

        // MARK: - Handle Task Completion
        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskViewControllerFinishReason,
            error: Error?
        ) {
            if reason == .completed {
                // Extract responses from task result
                let responses = extractResponses(from: taskViewController.result)

                // Create SurveyResponse object
                let surveyResponse = SurveyResponse(
                    id: UUID().uuidString,
                    surveyId: survey.id,
                    participantId: "", // Will be populated from auth
                    responses: responses,
                    completedAt: Date(),
                    isSynced: false
                )

                // Call completion handler
                onCompletion(surveyResponse)

                Logger.log("Survey \(survey.id) completed with \(responses.count) responses")
            } else if reason == .discarded {
                Logger.log("Survey \(survey.id) was discarded")
            } else if reason == .failed {
                Logger.error("Survey \(survey.id) failed: \(error?.localizedDescription ?? "Unknown error")")
            }

            taskViewController.dismiss(animated: true)
        }

        // MARK: - Extract Responses from ORKTaskResult
        private func extractResponses(from taskResult: ORKTaskResult) -> [String: AnyCodable] {
            var responses: [String: AnyCodable] = [:]

            if let stepResults = taskResult.results {
                for stepResult in stepResults {
                    if let questionResult = stepResult as? ORKQuestionResult,
                       let answer = questionResult.answer {
                        // Convert answer to AnyCodable
                        let codableAnswer = convertAnswerToAnyCodable(answer)
                        responses[questionResult.identifier] = codableAnswer
                    }
                }
            }

            return responses
        }

        // MARK: - Convert Answer to AnyCodable
        private func convertAnswerToAnyCodable(_ answer: Any) -> AnyCodable {
            if let stringAnswer = answer as? String {
                return AnyCodable(value: stringAnswer)
            } else if let numberAnswer = answer as? NSNumber {
                if CFNumberGetType(numberAnswer as CFNumber) == .charType {
                    return AnyCodable(value: numberAnswer.boolValue)
                } else if numberAnswer is Decimal {
                    return AnyCodable(value: numberAnswer.doubleValue)
                } else {
                    return AnyCodable(value: numberAnswer.intValue)
                }
            } else if let dateAnswer = answer as? Date {
                return AnyCodable(value: ISO8601DateFormatter().string(from: dateAnswer))
            } else if let arrayAnswer = answer as? [Any] {
                let codableArray = arrayAnswer.map { convertAnswerToAnyCodable($0) }
                return AnyCodable(value: codableArray)
            } else if let dictAnswer = answer as? [String: Any] {
                var codableDict: [String: AnyCodable] = [:]
                for (key, value) in dictAnswer {
                    codableDict[key] = convertAnswerToAnyCodable(value)
                }
                return AnyCodable(value: codableDict)
            } else {
                // Fallback to string representation
                return AnyCodable(value: String(describing: answer))
            }
        }

        // MARK: - Optional: Handle Step View Controller
        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            stepViewControllerWillAppear stepViewController: ORKStepViewController
        ) {
            Logger.log("Step appeared: \(stepViewController.step?.identifier ?? "unknown")")
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            stepViewControllerWillDisappear stepViewController: ORKStepViewController
        ) {
            Logger.log("Step disappearing: \(stepViewController.step?.identifier ?? "unknown")")
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.lightGreen.opacity(0.3).ignoresSafeArea()

        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.primaryGreen)

            Text("Survey Complete")
                .font(.title2)
                .fontWeight(.bold)

            Text("The ResearchKit survey controller will appear when you start a survey.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(20)
    }
}
