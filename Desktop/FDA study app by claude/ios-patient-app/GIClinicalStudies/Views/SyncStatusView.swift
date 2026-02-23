import SwiftUI

// MARK: - Sync Status View
struct SyncStatusView: View {
    @ObservedObject var syncEngine: SyncEngine
    @State private var showDetailedStatus = false

    var body: some View {
        VStack(spacing: 0) {
            // Status Bar
            HStack(spacing: 12) {
                // Status Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    if syncEngine.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8, anchor: .center)
                            .tint(.primaryGreen)
                    }

                    Text(syncEngine.getSyncStatus().statusMessage)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.dark)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 8) {
                    // Pending Count Badge
                    if syncEngine.pendingCount > 0 {
                        Text("\(syncEngine.pendingCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentOrange)
                            .cornerRadius(6)
                    }

                    // Sync Button
                    Button(action: {
                        syncEngine.manualSync()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.primaryGreen)
                    }
                    .disabled(syncEngine.isSyncing || !syncEngine.isOnline)

                    // Details Button
                    Button(action: { showDetailedStatus.toggle() }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(8)

            // Detailed Status Sheet
            if showDetailedStatus {
                DetailedSyncStatusView(syncEngine: syncEngine, isPresented: $showDetailedStatus)
            }
        }
    }

    private var statusColor: Color {
        if !syncEngine.isOnline {
            return Color.accentOrange
        } else if syncEngine.pendingCount > 0 {
            return Color.yellow
        } else {
            return Color.primaryGreen
        }
    }
}

// MARK: - Detailed Sync Status View
struct DetailedSyncStatusView: View {
    @ObservedObject var syncEngine: SyncEngine
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Sync Status")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            // Network Status
            VStack(alignment: .leading, spacing: 8) {
                Label("Network Status", systemImage: "network")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dark)

                HStack {
                    Circle()
                        .fill(syncEngine.isOnline ? Color.primaryGreen : Color.accentOrange)
                        .frame(width: 8, height: 8)

                    Text(syncEngine.isOnline ? "Online" : "Offline")
                        .font(.body)
                        .foregroundColor(.dark)

                    Spacer()

                    if !syncEngine.isOnline {
                        Text("Will sync when online")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)

            // Sync Status
            VStack(alignment: .leading, spacing: 8) {
                Label("Sync Progress", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dark)

                if syncEngine.isSyncing {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: syncEngine.syncProgress)
                            .tint(.primaryGreen)

                        Text("\(Int(syncEngine.syncProgress * 100))% complete")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                } else {
                    HStack {
                        Text("Not syncing")
                            .font(.body)
                            .foregroundColor(.dark)

                        Spacer()

                        Button(action: { syncEngine.manualSync() }) {
                            Text("Sync Now")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.primaryGreen)
                                .cornerRadius(6)
                        }
                        .disabled(!syncEngine.isOnline)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)

            // Queue Status
            VStack(alignment: .leading, spacing: 8) {
                Label("Pending Items", systemImage: "list.bullet")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dark)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Pending Responses")
                            .font(.body)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(syncEngine.pendingCount)")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryGreen)
                    }

                    if syncEngine.failedCount > 0 {
                        HStack {
                            Text("Failed (will retry)")
                                .font(.body)
                                .foregroundColor(.gray)

                            Spacer()

                            Text("\(syncEngine.failedCount)")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentOrange)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)

            // Last Sync Time
            if let lastSync = syncEngine.lastSyncTime {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Last Sync", systemImage: "clock.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.dark)

                    HStack {
                        Text(lastSync.formatted(date: .abbreviated, time: .standard))
                            .font(.body)
                            .foregroundColor(.dark)

                        Spacer()

                        Text("(\(timeAgoString(lastSync)) ago)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
            }

            // Error Message
            if let error = syncEngine.syncError {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Error", systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentOrange)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(nil)
                }
                .padding(12)
                .background(Color.accentOrange.opacity(0.1))
                .cornerRadius(8)
            }

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Label("Tips", systemImage: "lightbulb.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dark)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Data syncs automatically when online")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text("• Pending data is saved locally")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text("• Use 'Sync Now' to force sync")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text("• Check this screen for sync status")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)

            Spacer()

            // Clear Queue Button (for testing)
            #if DEBUG
            Button(action: {
                syncEngine.clearSyncQueue()
            }) {
                Text("Clear Sync Queue (Debug)")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.accentOrange)
                    .cornerRadius(8)
                    .font(.caption)
            }
            #endif
        }
        .padding(16)
        .background(Color.lightGreen.opacity(0.3))
        .cornerRadius(12)
    }

    private func timeAgoString(_ date: Date) -> String {
        let timeAgo = Date().timeIntervalSince(date)

        if timeAgo < 60 {
            return "just now"
        } else if timeAgo < 3600 {
            let minutes = Int(timeAgo / 60)
            return "\(minutes)m"
        } else if timeAgo < 86400 {
            let hours = Int(timeAgo / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeAgo / 86400)
            return "\(days)d"
        }
    }
}

// MARK: - Sync Status Indicator (Inline)
struct SyncStatusIndicator: View {
    @ObservedObject var syncEngine: SyncEngine

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            if syncEngine.isSyncing {
                ProgressView()
                    .scaleEffect(0.7, anchor: .center)
                    .tint(.primaryGreen)
            }

            Text(statusText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.dark)

            if syncEngine.pendingCount > 0 {
                Text("\(syncEngine.pendingCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentOrange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white)
        .cornerRadius(6)
    }

    private var statusColor: Color {
        if !syncEngine.isOnline {
            return Color.accentOrange
        } else if syncEngine.pendingCount > 0 {
            return Color.yellow
        } else {
            return Color.primaryGreen
        }
    }

    private var statusText: String {
        if !syncEngine.isOnline {
            return "Offline"
        } else if syncEngine.isSyncing {
            return "Syncing..."
        } else if syncEngine.pendingCount > 0 {
            return "Pending"
        } else {
            return "Synced"
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.lightGreen.opacity(0.3).ignoresSafeArea()

        VStack(spacing: 20) {
            SyncStatusView(syncEngine: SyncEngine.shared)
                .padding(16)

            Spacer()
        }
    }
}
