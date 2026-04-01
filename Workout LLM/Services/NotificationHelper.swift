import Foundation
import UserNotifications

/// Manages local notification scheduling for daily workout reminders.
enum NotificationHelper {

    private static let reminderIdentifier = "daily-workout-reminder"

    /// Request notification permission from the user.
    static func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Check current authorization status.
    static func checkPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    /// Schedule a repeating daily reminder at the given hour and minute.
    static func scheduleDailyReminder(hour: Int, minute: Int) {
        // Remove any existing reminder first
        cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "Time for your mobility routine"
        content.body = "Your joints will thank you. Today's workout is ready."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    /// Cancel the daily reminder.
    static func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}
