import Foundation
import UserNotifications
import Combine

// MARK: - Notification Manager
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var notifications: [LocalNotification] = []
    @Published var isNotificationsEnabled = false

    static let shared = NotificationManager()

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkNotificationSettings()
    }

    // MARK: - Public Methods

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = granted
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else if let error = error {
                    Logger.error("Notification permission error: \(error)")
                }
            }
        }
    }

    func scheduleSurveyReminder(survey: Survey, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Survey Reminder"
        content.body = "\(survey.title) is ready to complete"
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)

        // Add custom data
        content.userInfo = [
            "surveyId": survey.id,
            "studyId": survey.studyId,
            "type": "survey_reminder"
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Failed to schedule notification: \(error)")
            } else {
                Logger.log("Notification scheduled for \(survey.title)")
            }
        }
    }

    func scheduleStudyAnnouncementNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Failed to schedule announcement: \(error)")
            }
        }
    }

    func cancelNotifications(forSurveyId surveyId: String) {
        let pending = UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let toCancel = requests.filter { request in
                return request.content.userInfo["surveyId"] as? String == surveyId
            }

            let identifiers = toCancel.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.notifications = requests.map { request in
                    LocalNotification(
                        id: request.identifier,
                        title: request.content.title,
                        body: request.content.body,
                        date: (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date()
                    )
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        Logger.log("Notification received in foreground: \(userInfo)")

        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let surveyId = userInfo["surveyId"] as? String {
            Logger.log("User tapped survey reminder: \(surveyId)")
            // Navigate to survey (would be handled by app)
        }

        completionHandler()
    }

    // MARK: - Private Methods

    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
}

// MARK: - Local Notification Model
struct LocalNotification: Identifiable {
    let id: String
    let title: String
    let body: String
    let date: Date
}
