import Foundation
import os.log

// MARK: - Logger
struct Logger {
    static func log(_ message: String, category: String = "General") {
        #if DEBUG
        print("[📝 \(category)] \(message)")
        #endif

        let osLog = OSLog(subsystem: "com.giclinicalstudies.app", category: category)
        os_log("%{public}@", log: osLog, type: .info, message)
    }

    static func error(_ message: String, category: String = "Error") {
        #if DEBUG
        print("[❌ \(category)] \(message)")
        #endif

        let osLog = OSLog(subsystem: "com.giclinicalstudies.app", category: category)
        os_log("%{public}@", log: osLog, type: .error, message)
    }

    static func warning(_ message: String, category: String = "Warning") {
        #if DEBUG
        print("[⚠️ \(category)] \(message)")
        #endif

        let osLog = OSLog(subsystem: "com.giclinicalstudies.app", category: category)
        os_log("%{public}@", log: osLog, type: .default, message)
    }

    static func debug(_ message: String, category: String = "Debug") {
        #if DEBUG
        print("[🔍 \(category)] \(message)")

        let osLog = OSLog(subsystem: "com.giclinicalstudies.app", category: category)
        os_log("%{public}@", log: osLog, type: .debug, message)
        #endif
    }
}
