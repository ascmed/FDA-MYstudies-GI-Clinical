import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var studyViewModel: StudyViewModel
    @State private var refreshing = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.lightGreen.opacity(0.3).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // User Greeting
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Back")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(authViewModel.currentUser?.fullName ?? "Patient")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.dark)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)

                        // Active Studies Card
                        if !studyViewModel.studies.isEmpty {
                            VStack(spacing: 12) {
                                HStack {
                                    Label("Active Studies", systemImage: "book.fill")
                                        .font(.headline)
                                        .foregroundColor(.dark)

                                    Spacer()

                                    Text("\(studyViewModel.studies.count)")
                                        .font(.headline)
                                        .foregroundColor(.primaryGreen)
                                }

                                VStack(spacing: 8) {
                                    ForEach(studyViewModel.studies.prefix(3)) { study in
                                        StudyCardRow(study: study)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }

                        // Upcoming Surveys
                        VStack(spacing: 12) {
                            HStack {
                                Label("Upcoming Surveys", systemImage: "calendar")
                                    .font(.headline)
                                    .foregroundColor(.dark)

                                Spacer()
                            }

                            if studyViewModel.upcomingSurveys.isEmpty {
                                Text("No surveys scheduled")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(studyViewModel.upcomingSurveys.prefix(3)) { survey in
                                        SurveyCardRow(survey: survey)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)

                        // Study Progress
                        VStack(spacing: 12) {
                            HStack {
                                Label("Your Progress", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.headline)
                                    .foregroundColor(.dark)

                                Spacer()
                            }

                            if let metrics = studyViewModel.studyMetrics {
                                VStack(spacing: 12) {
                                    ProgressRow(
                                        label: "Study Completion",
                                        value: metrics.completionPercentage,
                                        color: .primaryGreen
                                    )

                                    ProgressRow(
                                        label: "Surveys Completed",
                                        value: Double(metrics.surveysCompleted) / Double(max(1, metrics.totalSurveys)) * 100,
                                        color: .secondaryGreen
                                    )

                                    Divider()

                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Days Remaining")
                                                .font(.caption)
                                                .foregroundColor(.gray)

                                            Text("\(metrics.daysRemaining)")
                                                .font(.headline)
                                                .foregroundColor(.primaryGreen)
                                        }

                                        Spacer()

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("On Track")
                                                .font(.caption)
                                                .foregroundColor(.gray)

                                            Image(systemName: metrics.isOnTrack ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                                .font(.headline)
                                                .foregroundColor(metrics.isOnTrack ? .primaryGreen : .accentOrange)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await refreshData() } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primaryGreen)
                    }
                }
            }
            .onAppear {
                studyViewModel.fetchStudies()
            }
        }
    }

    private func refreshData() async {
        refreshing = true
        studyViewModel.fetchStudies()
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        refreshing = false
    }
}

// MARK: - Study Card Row
struct StudyCardRow: View {
    let study: Study

    var body: some View {
        NavigationLink(destination: StudyDetailView(study: study)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(study.displayName)
                        .font(.headline)
                        .foregroundColor(.dark)

                    HStack(spacing: 8) {
                        Label(study.phase, systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("•")
                            .foregroundColor(.gray)

                        Text("\(study.durationWeeks)w")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(study.completionPercentage))%")
                        .font(.headline)
                        .foregroundColor(.primaryGreen)

                    ProgressView(value: study.completionPercentage / 100)
                        .frame(width: 60)
                        .tint(.primaryGreen)
                }
            }
            .padding(12)
            .background(
                Color(UIColor(red: CGFloat(0xFF) / 255, green: CGFloat(0xF7) / 255, blue: CGFloat(0xED) / 255, alpha: 1.0))
            )
            .cornerRadius(8)
        }
    }
}

// MARK: - Survey Card Row
struct SurveyCardRow: View {
    let survey: Survey

    var body: some View {
        NavigationLink(destination: SurveyDetailView(survey: survey)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(survey.title)
                        .font(.headline)
                        .foregroundColor(.dark)

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
                }

                Spacer()

                Image(systemImage: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}

// MARK: - Progress Row
struct ProgressRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Text("\(Int(value))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            ProgressView(value: value / 100)
                .tint(color)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(StudyViewModel())
}
