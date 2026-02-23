import SwiftUI
import UIKit

@main
struct GIClinicalStudiesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var studyViewModel = StudyViewModel()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(studyViewModel)
                    .environmentObject(notificationManager)
            } else if authViewModel.hasCompletedOnboarding {
                LoginView()
                    .environmentObject(authViewModel)
            } else {
                OnboardingView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure appearance
        configureAppearance()

        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermissions()

        // Setup analytics
        setupAnalytics()

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Logger.log("Device Token: \(token)")
        StorageService.shared.savePushToken(token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.error("Failed to register for remote notifications: \(error)")
    }

    // MARK: - Notification Delegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notification when app is in foreground
        let userInfo = notification.request.content.userInfo
        Logger.log("Notification received in foreground: \(userInfo)")

        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        Logger.log("User tapped notification: \(userInfo)")

        completionHandler()
    }

    // MARK: - Private Methods
    private func configureAppearance() {
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(named: "PrimaryGreen")
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance

        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                Logger.error("Notification permission error: \(error)")
            }
        }
    }

    private func setupAnalytics() {
        // Firebase Analytics setup
        #if !DEBUG
        FirebaseApp.configure()
        #endif
    }
}
