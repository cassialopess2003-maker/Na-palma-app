import Foundation
import SwiftData

/// Monthly spending limit for one expense category.
@Model
final class Budget {
    var categoryRaw: String = EntryCategory.food.rawValue
    var limit: Double = 0

    init(category: EntryCategory, limit: Double) {
        self.categoryRaw = category.rawValue
        self.limit = limit
    }

    var category: EntryCategory {
        get { EntryCategory(rawValue: categoryRaw) ?? .otherExpense }
        set { categoryRaw = newValue.rawValue }
    }
}

/// A budget together with what was spent in a given month.
struct BudgetStatus: Identifiable {
    let budget: Budget
    let spent: Double

    var id: PersistentIdentifier { budget.persistentModelID }
    var ratio: Double { budget.limit > 0 ? spent / budget.limit : 0 }
    var remaining: Double { budget.limit - spent }

    static func make(budgets: [Budget], entries: [FinanceEntry], month: Date) -> [BudgetStatus] {
        let expenses = entries.inMonth(month).filter { $0.kind == .expense }
        return budgets.map { budget in
            let spent = expenses.filter { $0.category == budget.category }.reduce(0) { $0 + $1.amount }
            return BudgetStatus(budget: budget, spent: spent)
        }
    }
}
