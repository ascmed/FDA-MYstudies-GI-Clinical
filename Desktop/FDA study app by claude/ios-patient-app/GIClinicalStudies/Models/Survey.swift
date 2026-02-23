import Foundation
import ResearchKit

// MARK: - Survey Model
struct Survey: Codable, Identifiable {
    let id: String
    let studyId: String
    let title: String
    let description: String?
    let surveyType: SurveyType
    let frequency: SurveyFrequency
    let isActive: Bool
    let questions: [Question]?
    let nextScheduledDate: Date?
    let lastCompletedDate: Date?
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case studyId = "study_id"
        case title
        case description
        case surveyType = "survey_type"
        case frequency
        case isActive = "is_active"
        case questions
        case nextScheduledDate = "next_scheduled_date"
        case lastCompletedDate = "last_completed_date"
        case displayOrder = "display_order"
    }

    var isOverdue: Bool {
        guard let nextDate = nextScheduledDate else { return false }
        return nextDate < Date()
    }

    var isDueToday: Bool {
        guard let nextDate = nextScheduledDate else { return false }
        return Calendar.current.isDateInToday(nextDate)
    }

    var isUpcoming: Bool {
        guard let nextDate = nextScheduledDate else { return false }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return nextDate > Date() && nextDate < tomorrow
    }
}

// MARK: - Survey Type
enum SurveyType: String, Codable {
    case baseline
    case weekly
    case monthly
    case followUp = "follow_up"
    case custom

    var displayName: String {
        switch self {
        case .baseline:
            return "Baseline Assessment"
        case .weekly:
            return "Weekly Check-In"
        case .monthly:
            return "Monthly Review"
        case .followUp:
            return "Follow-Up"
        case .custom:
            return "Custom Survey"
        }
    }
}

// MARK: - Survey Frequency
enum SurveyFrequency: String, Codable {
    case oneTime = "one_time"
    case weekly
    case biWeekly = "bi_weekly"
    case monthly
    case custom

    var displayName: String {
        switch self {
        case .oneTime:
            return "One Time"
        case .weekly:
            return "Weekly"
        case .biWeekly:
            return "Bi-weekly"
        case .monthly:
            return "Monthly"
        case .custom:
            return "Custom"
        }
    }

    var daysInterval: Int {
        switch self {
        case .oneTime:
            return 0
        case .weekly:
            return 7
        case .biWeekly:
            return 14
        case .monthly:
            return 30
        case .custom:
            return 0
        }
    }
}

// MARK: - Question
struct Question: Codable, Identifiable {
    let id: String
    let surveyId: String
    let questionText: String
    let questionType: QuestionType
    let isRequired: Bool
    let helpText: String?
    let displayOrder: Int
    let choices: [QuestionChoice]?

    enum CodingKeys: String, CodingKey {
        case id
        case surveyId = "survey_id"
        case questionText = "question_text"
        case questionType = "question_type"
        case isRequired = "is_required"
        case helpText = "help_text"
        case displayOrder = "display_order"
        case choices
    }

    func toORKQuestion() -> ORKQuestion {
        switch questionType {
        case .text:
            return ORKTextQuestion(identifier: id, title: questionText)

        case .multipleChoice:
            let choices = (self.choices ?? []).map { choice in
                ORKTextChoice(text: choice.choiceText, value: choice.choiceValue ?? choice.id)
            }
            let answerFormat = ORKValuePickerAnswerFormat(textChoices: choices)
            return ORKQuestion(identifier: id, title: questionText, answer: answerFormat)

        case .scale:
            let answerFormat = ORKScaleAnswerFormat(
                maximumValue: 10,
                minimumValue: 1,
                defaultValue: 5,
                step: 1
            )
            return ORKQuestion(identifier: id, title: questionText, answer: answerFormat)

        case .numeric:
            let answerFormat = ORKNumericAnswerFormat(style: .integer)
            return ORKQuestion(identifier: id, title: questionText, answer: answerFormat)

        case .date:
            let answerFormat = ORKDateAnswerFormat(style: .date)
            return ORKQuestion(identifier: id, title: questionText, answer: answerFormat)

        case .time:
            let answerFormat = ORKTimeOfDayAnswerFormat()
            return ORKQuestion(identifier: id, title: questionText, answer: answerFormat)
        }
    }
}

// MARK: - Question Type
enum QuestionType: String, Codable {
    case text
    case multipleChoice = "multiple_choice"
    case scale
    case numeric
    case date
    case time

    var displayName: String {
        switch self {
        case .text:
            return "Text Input"
        case .multipleChoice:
            return "Multiple Choice"
        case .scale:
            return "Rating Scale"
        case .numeric:
            return "Number"
        case .date:
            return "Date"
        case .time:
            return "Time"
        }
    }
}

// MARK: - Question Choice
struct QuestionChoice: Codable, Identifiable {
    let id: String
    let questionId: String
    let choiceText: String
    let choiceValue: String?
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case questionId = "question_id"
        case choiceText = "choice_text"
        case choiceValue = "choice_value"
        case displayOrder = "display_order"
    }
}

// MARK: - Survey Response
struct SurveyResponse: Codable, Identifiable {
    let id: String
    let surveyId: String
    let participantId: String
    let responses: [String: AnyCodable] // Question ID -> Response value
    let completedAt: Date
    let isSynced: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case surveyId = "survey_id"
        case participantId = "participant_id"
        case responses
        case completedAt = "completed_at"
        case isSynced = "is_synced"
    }

    var isOnTime: Bool {
        // Determined by comparing with scheduled date
        // Implementation depends on survey scheduling
        return true
    }
}

// MARK: - AnyCodable (for dynamic response values)
struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let val as Int:
            try container.encode(val)
        case let val as Double:
            try container.encode(val)
        case let val as Bool:
            try container.encode(val)
        case let val as String:
            try container.encode(val)
        case let val as [AnyCodable]:
            try container.encode(val)
        case let val as [String: AnyCodable]:
            try container.encode(val)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode AnyCodable"
                )
            )
        }
    }
}
