import SwiftUI

// MARK: - Enrollment Token View
struct EnrollmentTokenView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var enrollmentToken: String = ""
    @State private var showingError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.lightGreen.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primaryGreen)

                        Text("Enrollment Token")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.dark)

                        Text("Enter your enrollment token to join a study")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Token Input
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Token Code", systemImage: "lock")
                            .font(.headline)
                            .foregroundColor(.dark)

                        TextField("ABC123DEF456GHI789", text: $enrollmentToken)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.characters)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 20)

                    // Info Box
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Where to find your token", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.primaryGreen)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Your clinical coordinator will provide the token")
                            Text("2. Check your email for the enrollment letter")
                            Text("3. Contact your coordinator if you don't have it")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    Spacer()

                    // Enroll Button
                    Button(action: { enrollWithToken() }) {
                        if authViewModel.isLoading {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(.white)
                                Text("Enrolling...")
                            }
                        } else {
                            Text("Enroll in Study")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(enrollmentToken.isEmpty ? Color.gray : Color.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(enrollmentToken.isEmpty || authViewModel.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("New Enrollment")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Enrollment Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authViewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    private func enrollWithToken() {
        guard !enrollmentToken.trimmingCharacters(in: .whitespaces).isEmpty else {
            showingError = true
            authViewModel.errorMessage = "Please enter a valid enrollment token"
            return
        }

        authViewModel.enrollWithToken(enrollmentToken)
    }
}

#Preview {
    EnrollmentTokenView()
        .environmentObject(AuthViewModel())
}
