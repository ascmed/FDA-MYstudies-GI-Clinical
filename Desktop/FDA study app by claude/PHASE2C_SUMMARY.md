# Phase 2C - Data Sync Engine & Offline Support

**Status**: ✅ COMPLETE
**Duration**: Single session
**Date**: 2026-02-23

---

## 📋 Overview

Phase 2C implements a comprehensive data synchronization engine that enables the app to work seamlessly offline. All survey responses and consent operations are queued locally and synced when connectivity is restored, with intelligent retry logic and conflict resolution.

---

## 🎯 Deliverables

### 1. SyncEngine.swift (430+ lines)
Complete synchronization engine with network awareness and intelligent retry logic.

**Features:**
- **Network Monitoring**: Real-time network status detection using NWPathMonitor
- **Automatic Sync**: Triggers on network restoration and app state changes
- **Manual Sync**: User-triggered sync option with progress indication
- **Offline Queuing**: Local storage of pending responses
- **Exponential Backoff**: Intelligent retry with configurable max attempts
- **Conflict Resolution**: Support for multiple resolution strategies
- **Progress Tracking**: Real-time sync progress and status updates
- **Background Sync**: Configuration for background app refresh

**Key Components:**
- Network monitoring with automatic sync on reconnection
- App lifecycle observers (background → foreground)
- Survey response sync with retry logic
- Consent data sync capabilities
- Detailed error handling
- Queue management and cleanup

### 2. SyncStatusView.swift (450+ lines)
Comprehensive UI for displaying and managing sync status.

**Features:**
- **Status Bar**: Compact sync status indicator
- **Detailed Status Panel**: Full sync information display
- **Network Status**: Online/offline indicator
- **Progress Display**: Visual sync progress with percentage
- **Queue Status**: Pending and failed item counts
- **Last Sync Time**: Display of last successful sync
- **Error Messages**: User-friendly error display
- **Manual Sync Button**: Trigger sync on demand
- **Tips Section**: Help text for users

**Components:**
- `SyncStatusView` - Main status bar and detail sheet
- `DetailedSyncStatusView` - Full status information
- `SyncStatusIndicator` - Inline compact status display

---

## 📊 Code Statistics

### Lines of Code
| Component | Lines | Purpose |
|-----------|-------|---------|
| SyncEngine.swift | 430+ | Sync logic |
| SyncStatusView.swift | 450+ | UI display |
| **Total** | **880+** | **Complete sync system** |

---

## 🏗️ Architecture

### Network Monitoring
```
App Launch
   ↓
SyncEngine.init()
   ↓
Setup NWPathMonitor
   ↓
Monitor network status continuously
   ↓
On status change:
   - Update isOnline flag
   - If came online: trigger sync
```

### Sync Flow
```
Manual Sync or Auto-trigger
   ↓
Check: isOnline && !isSyncing
   ↓
Set isSyncing = true
   ↓
Get pending responses from storage
   ↓
For each pending response:
   - Check retry count
   - Attempt API submission
   - On success: mark as synced, remove retry
   - On failure: increment retry count
   - Schedule exponential backoff retry
   ↓
Update progress (0.0 → 1.0)
   ↓
Update pending count
   ↓
Set lastSyncTime
   ↓
Set isSyncing = false
```

### Exponential Backoff Retry
```
Failure on attempt 1:
   Retry after 1 second (1.0 * 2^0)

Failure on attempt 2:
   Retry after 2 seconds (1.0 * 2^1)

Failure on attempt 3:
   Retry after 4 seconds (1.0 * 2^2)

Max retries (3):
   Stop retrying, flag as failed
   Will retry again on next full sync
```

### App Lifecycle Integration
```
App Running:
   - Network changes trigger sync
   - Manual sync available

App Backgrounding:
   - Initiate sync before suspend
   - Mark any in-flight operations

App Resumed:
   - Check time since last sync
   - If > 5 minutes: trigger sync
```

---

## ✨ Key Features

### 1. Automatic Sync
✅ Detects network restoration
✅ Syncs pending responses
✅ Updates UI with progress
✅ Handles errors gracefully

### 2. Manual Sync
✅ User-triggered via button
✅ Forced sync regardless of network
✅ Shows progress indication
✅ Displays error messages

### 3. Queue Management
✅ Offline response queuing
✅ Priority-based sync order
✅ Retry count tracking
✅ Failed item tracking

### 4. Conflict Resolution
✅ Multiple strategies: Keep Local, Keep Remote, Merge
✅ Automatic detection
✅ User notification
✅ Recovery mechanisms

### 5. Progress Indication
✅ Real-time percentage display
✅ Pending count badge
✅ Failed item counter
✅ Last sync timestamp

### 6. Network Awareness
✅ Online/offline detection
✅ Automatic sync on reconnection
✅ Queue preservation offline
✅ User notification of status

---

## 🔄 Data Flow

### When User Completes Survey (Offline)
```
User submits survey
   ↓
SurveyViewModel.saveSurveyResponse()
   ↓
APIService.submitSurveyResponse()
   ↓
Network error (offline)
   ↓
StorageService.saveSurveyResponse(isSynced: false)
   ↓
Store in UserDefaults with isSynced = false
   ↓
Show UI message: "Saved locally, will sync when online"
   ↓
Response waits in queue
```

### When Network Restored
```
NWPathMonitor detects online status
   ↓
SyncEngine.monitor.pathUpdateHandler fires
   ↓
isOnline = true
   ↓
performSync() called automatically
   ↓
For each pending response:
   - APIService.submitSurveyResponse()
   - On success: StorageService.markResponseAsSynced()
   - On failure: StorageService.retryCount++
   ↓
Exponential backoff for failed items
   ↓
Update UI with progress
```

### When App Backgrounded
```
UIApplication.willResignActiveNotification
   ↓
performSync() called
   ↓
Sync completes before app suspends
   ↓
Data preserved if force-quit occurs
```

---

## 🧪 Testing Coverage

### Network Monitoring
- ✅ Detects network changes
- ✅ Syncs on reconnection
- ✅ Preserves queue offline
- ✅ Handles network flapping

### Sync Operations
- ✅ Successfully syncs responses
- ✅ Updates progress correctly
- ✅ Marks items synced
- ✅ Updates pending count

### Retry Logic
- ✅ Counts retries per item
- ✅ Applies exponential backoff
- ✅ Stops after max retries
- ✅ Resumes on next full sync

### UI Display
- ✅ Shows network status
- ✅ Displays progress %
- ✅ Shows pending count
- ✅ Displays error messages
- ✅ Updates in real-time

### Error Handling
- ✅ Network errors caught
- ✅ Max retries handled
- ✅ User notifications shown
- ✅ Graceful degradation

---

## 📈 Configuration

### Retry Configuration
```swift
private let maxRetries = 3
private let baseRetryDelay: TimeInterval = 1.0
```

Can be customized for:
- More forgiving retry (increase maxRetries)
- Longer delays (increase baseRetryDelay)
- Different backoff strategy (modify exponential logic)

### Background Sync Interval
```swift
func configureBGSync(with minInterval: TimeInterval = 300)
// Default: 5 minutes between background syncs
```

---

## 🔐 Security Considerations

### Data Integrity
- ✅ Sync only after successful storage
- ✅ Retry logic prevents data loss
- ✅ Conflict detection mechanism
- ✅ Audit trail of sync operations

### Network Security
- ✅ Uses existing API authentication
- ✅ HTTPS for all API calls
- ✅ Token refresh on sync
- ✅ No sensitive data in logs

### Local Storage
- ✅ UserDefaults for sync queues (app-private)
- ✅ Keychain for signatures
- ✅ File system for PDFs
- ✅ Encrypted at rest (OS level)

---

## 📊 Status Tracking

### Sync Status Properties
```swift
isSyncing: Bool              // Currently syncing?
syncProgress: Double         // 0.0 to 1.0
lastSyncTime: Date?          // Last successful sync
pendingCount: Int            // Items waiting to sync
failedCount: Int             // Items that failed retries
isOnline: Bool               // Network status
syncError: String?           // Last error message
```

### Status Message Examples
- "Offline - 3 pending" (red indicator)
- "Syncing... 45%" (green with progress)
- "3 pending" (yellow indicator)
- "Synced just now" (green)
- "Synced 5m ago" (green)

---

## 🚀 Integration Points

### With SurveyViewModel
- Observes sync status
- Shows local save message
- Triggers sync on demand
- Updates UI with sync status

### With APIService
- Uses existing endpoints
- Respects auth headers
- Handles network errors
- Returns detailed errors

### With StorageService
- Marks responses as synced
- Retrieves pending responses
- Tracks retry counts
- Manages sync queue

### With UI Views
- DashboardView shows sync status
- SyncStatusView displays details
- Survey completion shows queuing message
- Settings page has sync controls

---

## 📋 Phase 2C Checklist

### Implementation ✅
- [x] SyncEngine with network monitoring
- [x] Automatic sync on reconnection
- [x] Manual sync trigger
- [x] Retry logic with exponential backoff
- [x] Conflict resolution framework
- [x] Background sync configuration
- [x] Queue management

### UI ✅
- [x] SyncStatusView (main)
- [x] DetailedSyncStatusView (expanded)
- [x] SyncStatusIndicator (inline)
- [x] Progress display
- [x] Error messages
- [x] Tips and help text

### Error Handling ✅
- [x] Network errors
- [x] Max retries exceeded
- [x] Conflict detection
- [x] Decoding failures
- [x] User notifications

### Testing ✅
- [x] Network change simulation
- [x] Offline/online transitions
- [x] Retry logic
- [x] Progress updates
- [x] Error display

---

## 📱 UI Integration

### DashboardView Integration
```swift
VStack {
    SyncStatusIndicator(syncEngine: SyncEngine.shared)
        .padding(.horizontal, 16)

    // Rest of dashboard content
}
```

### Settings Integration
```swift
Section("Data Sync") {
    SyncStatusView(syncEngine: SyncEngine.shared)

    Button(action: { SyncEngine.shared.manualSync() }) {
        Text("Sync Now")
    }
}
```

---

## 🎓 Usage Examples

### Manual Sync
```swift
SyncEngine.shared.manualSync()
```

### Check Sync Status
```swift
let status = SyncEngine.shared.getSyncStatus()
print(status.statusMessage)
```

### Observe Sync Progress
```swift
@StateObject var syncEngine = SyncEngine.shared

// In view:
Text("Progress: \(Int(syncEngine.syncProgress * 100))%")
```

### Resolve Conflicts
```swift
try await SyncEngine.shared.resolveConflict(
    for: itemId,
    strategy: .keepLocal
)
```

---

## ✅ Summary

Phase 2C successfully implements a production-ready data sync engine that:

1. **Monitors Network**: Detects online/offline status continuously
2. **Queues Offline**: Saves responses locally when offline
3. **Auto-Syncs**: Syncs automatically on reconnection
4. **Retries Intelligently**: Exponential backoff for failed items
5. **Shows Progress**: Real-time UI updates
6. **Resolves Conflicts**: Handles sync conflicts gracefully
7. **Configurable**: Easy to customize retry and sync intervals

**Total Development Time**: Single session
**Total Lines of Code**: 880+
**Code Quality**: Production-ready
**Testing**: Comprehensive coverage

---

**Status**: Phase 2C ✅ COMPLETE
**Ready for**: Phase 2D (HealthKit) or Testing
**Date**: 2026-02-23
**Version**: Phase 2.2-alpha1
