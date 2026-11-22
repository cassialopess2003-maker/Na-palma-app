import Foundation
import SwiftData

/// A single income or expense.
/// Every stored property has a default value so the model can sync through CloudKit.
@Model
final class FinanceEntry {
    var title: String = ""
    var amount: Double = 0
    var date: Date = Date.now
    var kindRaw: String = EntryKind.expense.rawValue
    var categoryRaw: String = EntryCategory.otherExpense.rawValue
    var note: String = ""
    /// Set when the entry was created automatically by a recurring item.
    var recurringID: UUID?

    init(title: String, amount: Double, date: Date, kind: EntryKind, category: EntryCategory,
         note: String = "", recurringID: UUID? = nil) {
        self.title = title
        self.amount = amount
        self.date = date
        self.kindRaw = kind.rawValue
        self.categoryRaw = category.rawValue
        self.note = note
        self.recurringID = recurringID
    }

    var kind: EntryKind {
        get { EntryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    var category: EntryCategory {
        get { EntryCategory(rawValue: categoryRaw) ?? .otherExpense }
        set { categoryRaw = newValue.rawValue }
    }

    var signedAmount: Double { kind == .income ? amount : -amount }

    var displayTitle: String { title.isEmpty ? category.name : title }
}

extension Array where Element == FinanceEntry {
    func inMonth(_ month: Date) -> [FinanceEntry] {
        let start = month.startOfMonth
        let end = start.adding(months: 1)
        return filter { $0.date >= start && $0.date < end }
    }

    func total(_ kind: EntryKind) -> Double {
        filter { $0.kind == kind }.reduce(0) { $0 + $1.amount }
    }

    var balance: Double { reduce(0) { $0 + $1.signedAmount } }
}
