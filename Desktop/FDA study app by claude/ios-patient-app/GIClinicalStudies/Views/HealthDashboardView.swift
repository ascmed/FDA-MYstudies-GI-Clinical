import SwiftUI

// MARK: - Health Dashboard View
struct HealthDashboardView: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var showDetailedMetrics = false

    var body: some View {
        ZStack {
            Color.lightGreen.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Label("Health Metrics", systemImage: "heart.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.dark)

                    if !healthKitService.isAuthorized {
                        Text("Grant HealthKit access to view your health data")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Updated: \(Date().formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)

                if !healthKitService.isAuthorized {
                    // Authorization Required
                    VStack(spacing: 16) {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "heart.slash.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.primaryGreen)

                            Text("HealthKit Access Required")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.dark)

                            Text("Allow access to your health data to see metrics and auto-populate surveys")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)

                        Button(action: {
                            healthKitService.requestHealthKitAuthorization()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                Text("Grant HealthKit Access")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primaryGreen)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                } else if healthKitService.isLoading {
                    // Loading State
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.primaryGreen)

                        Text("Fetching health data...")
                            .font(.body)
                            .foregroundColor(.gray)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                } else if let healthData = healthKitService.latestHealthData {
                    // Health Data Display
                    ScrollView {
                        VStack(spacing: 12) {
                            // Steps Card
                            HealthMetricCard(
                                icon: "figure.walk",
                                title: "Steps",
                                value: "\(healthData.stepCount)",
                                unit: "steps",
                                color: .primaryGreen,
                                recommendation: "Goal: 10,000 steps/day"
                            )

                            // Heart Rate Card
                            HealthMetricCard(
                                icon: "heart.fill",
                                title: "Heart Rate",
                                value: "\(healthData.heartRate)",
                                unit: "bpm",
                                color: .accentOrange,
                                recommendation: "Normal: 60-100 bpm at rest"
                            )

                            // Blood Pressure Card
                            if let bp = healthData.bloodPressure {
                                HealthMetricCard(
                                    icon: "waveform.circle.fill",
                                    title: "Blood Pressure",
                                    value: "\(bp.systolic)/\(bp.diastolic)",
                                    unit: "mmHg",
                                    color: bp.isNormal ? .primaryGreen : (bp.isElevated ? .yellow : .accentOrange),
                                    recommendation: "Category: \(bp.category)"
                                )
                            }

                            // Weight Card
                            if healthData.weight > 0 {
                                HealthMetricCard(
                                    icon: "scalemass.fill",
                                    title: "Weight",
                                    value: String(format: "%.1f", healthData.weight),
                                    unit: "lbs",
                                    color: .secondaryGreen,
                                    recommendation: "Track trends over time"
                                )
                            }

                            // Active Energy Card
                            HealthMetricCard(
                                icon: "flame.fill",
                                title: "Active Energy",
                                value: "\(healthData.activeEnergy)",
                                unit: "kcal",
                                color: .primaryGreen,
                                recommendation: "Goal: 300+ kcal/day"
                            )

                            // Sleep Card
                            if healthData.sleepDuration > 0 {
                                HealthMetricCard(
                                    icon: "moon.stars.fill",
                                    title: "Sleep",
                                    value: "\(healthData.sleepDuration)",
                                    unit: "hours",
                                    color: .secondaryGreen,
                                    recommendation: "Recommended: 7-9 hours/night"
                                )
                            }

                            // Data Summary
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Summary", systemImage: "list.bullet")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dark)

                                Text(healthData.summary)
                                    .font(.body)
                                    .foregroundColor(.dark)
                                    .lineLimit(nil)
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)

                            // Tips
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Tips for Better Health", systemImage: "lightbulb.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dark)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Aim for 10,000 steps daily for cardiovascular health")
                                        .font(.caption2)
                                        .foregroundColor(.gray)

                                    Text("• Monitor blood pressure regularly, especially with existing conditions")
                                        .font(.caption2)
                                        .foregroundColor(.gray)

                                    Text("• Maintain consistent sleep schedule for better health outcomes")
                                        .font(.caption2)
                                        .foregroundColor(.gray)

                                    Text("• Track weight trends, focus on consistency not daily changes")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }

                    // Refresh Button
                    Button(action: {
                        healthKitService.fetchLatestHealthData()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Health Data")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                } else {
                    // No Data
                    VStack(spacing: 16) {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)

                            Text("No Health Data Available")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.dark)

                            Text("Add health data in Apple Health to see it here")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)

                        Button(action: {
                            healthKitService.fetchLatestHealthData()
                        }) {
                            Text("Try Again")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.primaryGreen)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }

                // Error Message
                if let error = healthKitService.errorMessage {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.accentOrange)

                            Text(error)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(nil)

                            Spacer()

                            Button(action: { healthKitService.errorMessage = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(12)
                        .background(Color.accentOrange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Health Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if healthKitService.isAuthorized {
                healthKitService.fetchLatestHealthData()
            }
        }
    }
}

// MARK: - Health Metric Card Component
struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let recommendation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.dark)

                    HStack(spacing: 4) {
                        Text(value)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(color)

                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }

            Divider()

            Text(recommendation)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(nil)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        HealthDashboardView()
    }
}
