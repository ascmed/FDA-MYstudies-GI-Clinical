import SwiftUI

// MARK: - Survey List View
struct SurveyListView: View {
    @EnvironmentObject var studyViewModel: StudyViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.lightGreen.opacity(0.3).ignoresSafeArea()

                if studyViewModel.upcomingSurveys.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checklist.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primaryGreen)

                        Text("No Surveys")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.dark)

                        Text("Check back later for new surveys")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        ForEach(studyViewModel.upcomingSurveys) { survey in
                            NavigationLink(destination: SurveyDetailView(survey: survey)) {
                                SurveyListRow(survey: survey)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Surveys")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Survey List Row
struct SurveyListRow: View {
    let survey: Survey

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(survey.title)
                        .font(.headline)
                        .foregroundColor(.dark)

                    HStack(spacing: 8) {
                        if survey.isOverdue {
                            Label("Overdue", systemImage: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.accentOrange)
                        } else if survey.isDueToday {
                            Label("Due Today", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.primaryGreen)
                        } else if survey.isUpcoming {
                            Label("Tomorrow", systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondaryGreen)
                        }

                        Text("•")
                            .foregroundColor(.gray)

                        Text(survey.frequency.displayName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Image(systemImage: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SurveyListView()
        .environmentObject(StudyViewModel())
}
