import Foundation
import SwiftData

/// A fixed monthly income or bill (rent, salary, subscriptions...).
/// The app creates the matching entry automatically each month and can remind the user before bills are due.
@Model
final class RecurringItem {
    var uid: UUID = UUID()
    var title: String = ""
    var amount: Double = 0
    var kindRaw: String = EntryKind.expense.rawValue
    var categoryRaw: String = EntryCategory.bills.rawValue
    var dayOfMonth: Int = 1
    var startDate: Date = Date.now
    var lastGenerated: Date?
    var remind: Bool = true
    var remindDaysBefore: Int = 1
    var isActive: Bool = true

    init(title: String, amount: Double, kind: EntryKind, category: EntryCategory, dayOfMonth: Int,
         startDate: Date = .now, remind: Bool = true, remindDaysBefore: Int = 1) {
        self.uid = UUID()
        self.title = title
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.categoryRaw = category.rawValue
        self.dayOfMonth = dayOfMonth
        self.startDate = startDate
        self.remind = remind
        self.remindDaysBefore = remindDaysBefore
    }

    var kind: EntryKind {
        get { EntryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    var category: EntryCategory {
        get { EntryCategory(rawValue: categoryRaw) ?? .otherExpense }
        set { categoryRaw = newValue.rawValue }
    }

    var displayTitle: String { title.isEmpty ? category.name : title }

    /// The due date inside the given month (clamped to the month's last day, e.g. day 31 in February).
    func dueDate(in month: Date) -> Date {
        let calendar = Calendar.current
        let start = month.startOfMonth
        let daysInMonth = calendar.range(of: .day, in: .month, for: start)?.count ?? 28
        let day = min(max(dayOfMonth, 1), daysInMonth)
        return calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
    }

    /// Next due date from today (today included).
    func nextDueDate(from now: Date = .now) -> Date {
        let today = Calendar.current.startOfDay(for: now)
        let thisMonth = dueDate(in: now)
        return thisMonth >= today ? thisMonth : dueDate(in: now.adding(months: 1))
    }
}
