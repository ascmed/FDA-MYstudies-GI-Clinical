import Foundation
import UIKit

// MARK: - Bundle Extensions
extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Date Extensions
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var daysUntilNow: Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: Date())
        return components.day ?? 0
    }

    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }

    func timeUntilNow() -> String {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: self,
            to: Date()
        )

        if let year = components.year, year > 0 {
            return "\(year)y ago"
        } else if let month = components.month, month > 0 {
            return "\(month)mo ago"
        } else if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        return predicate.evaluate(with: self)
    }

    var isValidEnrollmentToken: Bool {
        // Token should be alphanumeric and 16+ characters
        let pattern = "^[A-Z0-9]{16,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self.uppercased())
    }

    func attributed(with color: UIColor) -> NSAttributedString {
        NSAttributedString(
            string: self,
            attributes: [.foregroundColor: color]
        )
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    static let primaryGreen = UIColor(named: "PrimaryGreen") ?? UIColor(red: 0.1, green: 0.42, blue: 0.29, alpha: 1.0)
    static let secondaryGreen = UIColor(named: "SecondaryGreen") ?? UIColor(red: 0.18, green: 0.62, blue: 0.43, alpha: 1.0)
    static let lightGreen = UIColor(named: "LightGreen") ?? UIColor(red: 0.91, green: 0.96, blue: 0.94, alpha: 1.0)
    static let accentOrange = UIColor(red: 0.76, green: 0.25, blue: 0.05, alpha: 1.0)
    static let accentPurple = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1.0)
    static let accentBlue = UIColor(red: 0.02, green: 0.41, blue: 0.63, alpha: 1.0)

    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0

        Scanner(string: hex).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

// MARK: - Array Extensions
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let authTokenExpired = Notification.Name("authTokenExpired")
    static let syncRequired = Notification.Name("syncRequired")
    static let studyEnrolled = Notification.Name("studyEnrolled")
}
