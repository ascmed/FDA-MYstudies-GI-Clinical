import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var studyViewModel: StudyViewModel

    var body: some View {
        TabView {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            // Studies Tab
            StudyListView()
                .tabItem {
                    Label("Studies", systemImage: "book.fill")
                }

            // Surveys Tab
            SurveyListView()
                .tabItem {
                    Label("Surveys", systemImage: "checklist")
                }

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.primaryGreen)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(StudyViewModel())
}
