import SwiftUI

// MARK: - Study List View
struct StudyListView: View {
    @EnvironmentObject var studyViewModel: StudyViewModel
    @State private var showEnrollmentSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.lightGreen.opacity(0.3).ignoresSafeArea()

                if studyViewModel.studies.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primaryGreen)

                        Text("No Studies Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.dark)

                        Text("Enroll in a clinical study to get started")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Button(action: { showEnrollmentSheet.toggle() }) {
                            Label("Enroll in Study", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.primaryGreen)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                } else {
                    List {
                        ForEach(studyViewModel.studies) { study in
                            NavigationLink(destination: StudyDetailView(study: study)) {
                                StudyListRow(study: study)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Studies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEnrollmentSheet.toggle() }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryGreen)
                    }
                }
            }
            .sheet(isPresented: $showEnrollmentSheet) {
                EnrollmentTokenView()
            }
        }
    }
}

// MARK: - Study List Row
struct StudyListRow: View {
    let study: Study

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(study.displayName)
                        .font(.headline)
                        .foregroundColor(.dark)

                    Text(study.studyId)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(study.completionPercentage))%")
                        .font(.headline)
                        .foregroundColor(.primaryGreen)

                    Text("Complete")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            ProgressView(value: study.completionPercentage / 100)
                .tint(.primaryGreen)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StudyListView()
        .environmentObject(StudyViewModel())
}
