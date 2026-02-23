import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Background
            Color.lightGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.primaryGreen : Color.gray)
                            .frame(height: 8)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)

                // Tab View for Onboarding Pages
                TabView(selection: $currentPage) {
                    OnboardingPage1()
                        .tag(0)

                    OnboardingPage2()
                        .tag(1)

                    OnboardingPage3()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Navigation Buttons
                HStack(spacing: 16) {
                    Button(action: { previousPage() }) {
                        Text("Back")
                            .font(.headline)
                            .foregroundColor(.primaryGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .opacity(currentPage == 0 ? 0 : 1)

                    Button(action: { nextPage() }) {
                        Text(currentPage == 2 ? "Get Started" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primaryGreen)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private func previousPage() {
        withAnimation {
            currentPage = max(0, currentPage - 1)
        }
    }

    private func nextPage() {
        if currentPage < 2 {
            withAnimation {
                currentPage += 1
            }
        }
    }
}

// MARK: - Onboarding Page 1
struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryGreen)

            VStack(spacing: 12) {
                Text("Welcome to GI Clinical Studies")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dark)

                Text("Participate in groundbreaking research to advance gastroenterology treatments")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Onboarding Page 2
struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryGreen)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Privacy is Protected")
                            .font(.headline)
                            .foregroundColor(.dark)

                        Text("HIPAA compliant and encrypted")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }

                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryGreen)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smart Reminders")
                            .font(.headline)
                            .foregroundColor(.dark)

                        Text("Get notified when surveys are due")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }

                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryGreen)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Track Your Progress")
                            .font(.headline)
                            .foregroundColor(.dark)

                        Text("See your study participation metrics")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Onboarding Page 3
struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryGreen)

            VStack(spacing: 12) {
                Text("Ready to Participate?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dark)

                Text("You'll receive an enrollment token from your clinical coordinator. Have it ready to get started.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
