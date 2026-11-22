import Foundation
import SwiftData

/// Creates the monthly entries for every active recurring item, up to today.
@MainActor
enum RecurrenceEngine {
    static func run(in context: ModelContext, now: Date = .now) {
        guard let items = try? context.fetch(FetchDescriptor<RecurringItem>()), !items.isEmpty else { return }
        let entries = (try? context.fetch(FetchDescriptor<FinanceEntry>())) ?? []
        let calendar = Calendar.current
        var changed = false

        for item in items where item.isActive {
            let firstDay = calendar.startOfDay(for: item.startDate)
            let generated = entries.filter { $0.recurringID == item.uid }
            var month = (item.lastGenerated?.adding(months: 1) ?? item.startDate).startOfMonth

            while month <= now {
                let due = item.dueDate(in: month)
                if due > now { break }

                let alreadyExists = generated.contains {
                    calendar.isDate($0.date, equalTo: due, toGranularity: .month)
                }
                if due >= firstDay && !alreadyExists {
                    context.insert(FinanceEntry(title: item.title, amount: item.amount, date: due,
                                                kind: item.kind, category: item.category,
                                                recurringID: item.uid))
                }
                item.lastGenerated = due
                changed = true
                month = month.adding(months: 1)
            }
        }

        if changed { try? context.save() }
    }
}
