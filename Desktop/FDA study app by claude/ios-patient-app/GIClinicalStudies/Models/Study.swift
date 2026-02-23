import Foundation

// MARK: - Study Model
struct Study: Codable, Identifiable {
    let id: String
    let studyId: String
    let title: String
    let description: String?
    let diseaseArea: String // UC, CD, NASH
    let phase: String
    let durationWeeks: Int
    let status: StudyStatus
    let createdAt: Date
    let enrolledAt: Date?
    let completionPercentage: Double
    let color: String // Hex color code

    enum CodingKeys: String, CodingKey {
        case id
        case studyId = "study_id"
        case title
        case description
        case diseaseArea = "disease_area"
        case phase
        case durationWeeks = "duration_weeks"
        case status
        case createdAt = "created_at"
        case enrolledAt = "enrolled_at"
        case completionPercentage = "completion_percentage"
        case color
    }

    var diseaseAreaColor: String {
        switch diseaseArea {
        case "UC":
            return "#C2410C" // Orange
        case "CD":
            return "#7C3AED" // Purple
        case "NASH":
            return "#0369A1" // Blue
        default:
            return "#1A6B4A" // Green
        }
    }

    var displayName: String {
        switch diseaseArea {
        case "UC":
            return "Ulcerative Colitis"
        case "CD":
            return "Crohn's Disease"
        case "NASH":
            return "Hepatic Steatosis"
        default:
            return diseaseArea
        }
    }
}

// MARK: - Study Status
enum StudyStatus: String, Codable {
    case draft
    case published
    case paused
    case archived
    case completed

    var displayName: String {
        rawValue.capitalized
    }

    var isActive: Bool {
        self == .published
    }
}

// MARK: - Study Details
struct StudyDetails: Codable {
    let study: Study
    let surveys: [Survey]
    let consentForm: ConsentForm?
    let resources: [StudyResource]
    let nextSurveyDate: Date?
    let progressMetrics: StudyMetrics

    enum CodingKeys: String, CodingKey {
        case study
        case surveys
        case consentForm = "consent_form"
        case resources
        case nextSurveyDate = "next_survey_date"
        case progressMetrics = "progress_metrics"
    }
}

// MARK: - Study Metrics
struct StudyMetrics: Codable {
    let completionPercentage: Double
    let surveysCompleted: Int
    let totalSurveys: Int
    let daysRemaining: Int
    let lastActivityDate: Date?

    enum CodingKeys: String, CodingKey {
        case completionPercentage = "completion_percentage"
        case surveysCompleted = "surveys_completed"
        case totalSurveys = "total_surveys"
        case daysRemaining = "days_remaining"
        case lastActivityDate = "last_activity_date"
    }

    var isOnTrack: Bool {
        // Calculate expected completion percentage based on time elapsed
        let daysPassed = max(1, -daysRemaining) // Simplified
        let expectedCompletion = min(100.0, Double(daysPassed) * 2.0) // 2% per day

        return completionPercentage >= (expectedCompletion * 0.8) // Allow 20% buffer
    }
}

// MARK: - Study Resource
struct StudyResource: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let resourceType: ResourceType
    let url: String?
    let fileName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case resourceType = "resource_type"
        case url
        case fileName = "file_name"
    }
}

enum ResourceType: String, Codable {
    case pdf
    case link
    case video
    case image
    case text

    var icon: String {
        switch self {
        case .pdf:
            return "📄"
        case .link:
            return "🔗"
        case .video:
            return "📹"
        case .image:
            return "🖼️"
        case .text:
            return "📝"
        }
    }
}

// MARK: - Enrollment Response
struct EnrollmentResponse: Codable {
    let study: Study
    let consentForm: ConsentForm?
    let nextSteps: String

    enum CodingKeys: String, CodingKey {
        case study
        case consentForm = "consent_form"
        case nextSteps = "next_steps"
    }
}
