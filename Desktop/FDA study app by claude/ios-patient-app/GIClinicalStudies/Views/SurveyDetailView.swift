import SwiftUI
import ResearchKit

// MARK: - Survey Detail View
struct SurveyDetailView: View {
    let survey: Survey
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SurveyViewModel()
    @State private var showingResearchKit = false

    var body: some View {
        ZStack {
            Color.lightGreen.opacity(0.3).ignoresSafeArea()

            if showingResearchKit {
                ResearchKitSurveyController(
                    survey: survey,
                    onCompletion: { response in
                        viewModel.saveSurveyResponse(response)
                        dismiss()
                    }
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Survey Header
                            SurveyHeaderCard(survey: survey)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)

                            // Survey Info Section
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Survey Details", systemImage: "info.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.dark)

                                if let description = survey.description {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(description)
                                            .font(.body)
                                            .foregroundColor(.gray)
                                            .lineLimit(nil)
                                    }
                                }

                                Divider()

                                // Status and Frequency
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Type")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(survey.surveyType.displayName)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.dark)
                                    }

                                    Spacer()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Frequency")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(survey.frequency.displayName)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.dark)
                                    }
                                }

                                Divider()

                                // Due Status
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Status")
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    HStack(spacing: 8) {
                                        if survey.isOverdue {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.accentOrange)
                                            Text("Overdue")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.accentOrange)
                                        } else if survey.isDueToday {
                                            Image(systemImage: "clock.fill")
                                                .foregroundColor(.primaryGreen)
                                            Text("Due Today")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primaryGreen)
                                        } else if survey.isUpcoming {
                                            Image(systemImage: "calendar")
                                                .foregroundColor(.secondaryGreen)
                                            Text("Upcoming")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondaryGreen)
                                        } else {
                                            Image(systemImage: "checkmark.circle.fill")
                                                .foregroundColor(.gray)
                                            Text("Completed")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)

                            // Questions Preview Section
                            if let questions = survey.questions, !questions.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Questions Preview", systemImage: "questionmark.circle.fill")
                                        .font(.headline)
                                        .foregroundColor(.dark)

                                    VStack(spacing: 12) {
                                        ForEach(questions.prefix(5)) { question in
                                            QuestionPreviewRow(question: question)
                                        }

                                        if questions.count > 5 {
                                            HStack {
                                                Text("and \(questions.count - 5) more question\(questions.count - 5 > 1 ? "s" : "")")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }

                            // Time Information
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Time & Schedule", systemImage: "clock.fill")
                                    .font(.headline)
                                    .foregroundColor(.dark)

                                if let nextDate = survey.nextScheduledDate {
                                    InfoRow(
                                        label: "Next Due",
                                        value: nextDate.formatted(date: .abbreviated, time: .omitted)
                                    )
                                }

                                if let lastDate = survey.lastCompletedDate {
                                    InfoRow(
                                        label: "Last Completed",
                                        value: lastDate.formatted(date: .abbreviated, time: .omitted)
                                    )
                                } else {
                                    InfoRow(
                                        label: "Last Completed",
                                        value: "Not yet completed"
                                    )
                                }

                                InfoRow(
                                    label: "Estimated Duration",
                                    value: estimatedDuration
                                )
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)

                            // Tips Section
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Tips", systemImage: "lightbulb.fill")
                                    .font(.headline)
                                    .foregroundColor(.dark)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("• Find a quiet place to complete this survey")
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    Text("• The survey should take approximately \(estimatedDuration)")
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    Text("• Your responses are encrypted and secure")
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    Text("• You can save and return later if needed")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }

                    // Begin Survey Button
                    VStack(spacing: 12) {
                        Button(action: { showingResearchKit.toggle() }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Begin Survey")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primaryGreen)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        Button(action: { dismiss() }) {
                            Text("Review Later")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.primaryGreen)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.primaryGreen, lineWidth: 1)
                                )
                        }
                    }
                    .padding(16)
                    .background(Color.white.shadow(radius: 4))
                }
            }
        }
        .navigationTitle("Survey")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadSurveyDetails(survey: survey)
        }
    }

    private var estimatedDuration: String {
        guard let questionCount = survey.questions?.count else { return "5-10 minutes" }
        // Estimate: ~30 seconds per question on average
        let estimatedSeconds = questionCount * 30
        let minutes = estimatedSeconds / 60

        if minutes < 1 {
            return "Less than 1 minute"
        } else if minutes <= 5 {
            return "\(minutes) minutes"
        } else if minutes <= 15 {
            return "\(minutes) minutes"
        } else {
            return "15+ minutes"
        }
    }
}

// MARK: - Survey Header Card
struct SurveyHeaderCard: View {
    let survey: Survey

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(survey.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.dark)
                        .lineLimit(nil)

                    HStack(spacing: 4) {
                        Image(systemImage: "doc.text.fill")
                            .font(.caption)
                        Text("Survey ID: \(survey.id.prefix(8))...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    if let questionCount = survey.questions?.count {
                        Text("\(questionCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryGreen)

                        Text("Question\(questionCount != 1 ? "s" : "")")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }

            Divider()

            // Status Badge
            HStack {
                if survey.isOverdue {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentOrange)
                        .cornerRadius(6)
                } else if survey.isDueToday {
                    Label("Due Today", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primaryGreen)
                        .cornerRadius(6)
                } else if survey.isUpcoming {
                    Label("Upcoming", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondaryGreen)
                        .cornerRadius(6)
                } else {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .cornerRadius(6)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemImage: "repeat")
                        .font(.caption)
                    Text(survey.frequency.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.dark)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Question Preview Row
struct QuestionPreviewRow: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.questionText)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.dark)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(question.questionType.displayName)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.lightGreen.opacity(0.3))
                            .cornerRadius(4)

                        if question.isRequired {
                            Text("Required")
                                .font(.caption2)
                                .foregroundColor(.accentOrange)
                        }
                    }
                }

                Spacer()

                if let choices = question.choices, !choices.isEmpty {
                    Text("\(choices.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondaryGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondaryGreen.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            if let helpText = question.helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding(12)
        .background(Color.lightGreen.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.dark)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SurveyDetailView(
            survey: Survey(
                id: "survey_001",
                studyId: "study_001",
                title: "Weekly Symptom Check-in",
                description: "Please rate your current symptoms and any changes from last week.",
                surveyType: .weekly,
                frequency: .weekly,
                isActive: true,
                questions: [
                    Question(
                        id: "q1",
                        surveyId: "survey_001",
                        questionText: "How would you rate your overall symptom severity today?",
                        questionType: .scale,
                        isRequired: true,
                        helpText: "1 = Minimal, 10 = Severe",
                        displayOrder: 1,
                        choices: nil
                    ),
                    Question(
                        id: "q2",
                        surveyId: "survey_001",
                        questionText: "Have you experienced any new symptoms?",
                        questionType: .multipleChoice,
                        isRequired: true,
                        helpText: nil,
                        displayOrder: 2,
                        choices: [
                            QuestionChoice(id: "c1", questionId: "q2", choiceText: "Yes", choiceValue: "yes", displayOrder: 1),
                            QuestionChoice(id: "c2", questionId: "q2", choiceText: "No", choiceValue: "no", displayOrder: 2),
                            QuestionChoice(id: "c3", questionId: "q2", choiceText: "Not sure", choiceValue: "unsure", displayOrder: 3)
                        ]
                    )
                ],
                nextScheduledDate: Date().addingTimeInterval(86400), // Tomorrow
                lastCompletedDate: Date().addingTimeInterval(-604800), // Last week
                displayOrder: 1
            )
        )
    }
}
