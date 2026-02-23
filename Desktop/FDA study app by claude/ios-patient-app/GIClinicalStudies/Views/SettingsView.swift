import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var notificationsEnabled = true
    @State private var biometricEnabled = true

    var body: some View {
        NavigationView {
            ZStack {
                Color.lightGreen.opacity(0.3).ignoresSafeArea()

                Form {
                    // User Section
                    Section("Account") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Email", systemImage: "envelope.fill")
                                .foregroundColor(.dark)

                            Text(authViewModel.currentUser?.email ?? "Not Set")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)

                        if let userName = authViewModel.currentUser?.fullName {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Name", systemImage: "person.fill")
                                    .foregroundColor(.dark)

                                Text(userName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Preferences Section
                    Section("Preferences") {
                        Toggle("Survey Notifications", isOn: $notificationsEnabled)
                            .tint(.primaryGreen)

                        Toggle("Biometric Login", isOn: $biometricEnabled)
                            .tint(.primaryGreen)
                    }

                    // App Info Section
                    Section("App Info") {
                        HStack {
                            Text("Version")
                                .foregroundColor(.gray)

                            Spacer()

                            Text("\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                                .foregroundColor(.dark)
                        }

                        HStack {
                            Text("Build Date")
                                .foregroundColor(.gray)

                            Spacer()

                            Text(Date().formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.dark)
                        }
                    }

                    // Support Section
                    Section("Support") {
                        Link(destination: URL(string: "https://giclinicalstudies.com/privacy")!) {
                            Label("Privacy Policy", systemImage: "lock.fill")
                                .foregroundColor(.primaryGreen)
                        }

                        Link(destination: URL(string: "https://giclinicalstudies.com/terms")!) {
                            Label("Terms of Service", systemImage: "doc.fill")
                                .foregroundColor(.primaryGreen)
                        }

                        Link(destination: URL(string: "mailto:support@giclinicalstudies.com")!) {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundColor(.primaryGreen)
                        }
                    }

                    // Logout Section
                    Section {
                        Button(role: .destructive) {
                            authViewModel.logout()
                        } label: {
                            Label("Logout", systemImage: "power")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
