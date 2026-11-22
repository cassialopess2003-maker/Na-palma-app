import Foundation
import UserNotifications

/// Local monthly notifications for recurring bills.
enum BillReminders {
    static var center: UNUserNotificationCenter { .current() }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    static func schedule(_ item: RecurringItem) {
        let id = item.uid.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard item.isActive, item.remind, item.kind == .expense else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Bill reminder")
        content.body = String(localized: "\(item.displayTitle) (\(item.amount.currencyText)) is due on day \(item.dayOfMonth).")
        content.sound = .default

        var components = DateComponents()
        // Days 29–31 don't exist in every month, so reminders are capped at day 28.
        components.day = min(max(item.dayOfMonth - item.remindDaysBefore, 1), 28)
        components.hour = 9

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func cancel(_ item: RecurringItem) {
        center.removePendingNotificationRequests(withIdentifiers: [item.uid.uuidString])
    }

    static func rescheduleAll(_ items: [RecurringItem]) {
        center.removeAllPendingNotificationRequests()
        items.forEach(schedule)
    }
}
