import Foundation
import SwiftData

enum Persistence {
    static let schema = Schema([FinanceEntry.self, Budget.self, SavingsGoal.self, RecurringItem.self])

    /// Uses iCloud (CloudKit private database) when the app is signed with the iCloud
    /// capability, and falls back to on-device storage otherwise.
    static func makeContainer() -> ModelContainer {
        do {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: cloud)
        } catch {
            print("iCloud container unavailable, using local storage: \(error)")
            do {
                let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                return try ModelContainer(for: schema, configurations: local)
            } catch {
                fatalError("Could not create the data store: \(error)")
            }
        }
    }

    @MainActor
    static let preview: ModelContainer = {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let ctx = container.mainContext
        let now = Date.now
        func day(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: -offset, to: now)! }
        ctx.insert(FinanceEntry(title: "Salary", amount: 5200, date: day(3), kind: .income, category: .salary))
        ctx.insert(FinanceEntry(title: "Supermarket", amount: 412.35, date: day(1), kind: .expense, category: .groceries))
        ctx.insert(FinanceEntry(title: "Rent", amount: 1800, date: day(2), kind: .expense, category: .housing))
        ctx.insert(FinanceEntry(title: "Uber", amount: 28.9, date: day(0), kind: .expense, category: .transport))
        ctx.insert(FinanceEntry(title: "Cinema", amount: 64, date: day(4), kind: .expense, category: .leisure))
        ctx.insert(Budget(category: .groceries, limit: 500))
        ctx.insert(Budget(category: .leisure, limit: 300))
        ctx.insert(SavingsGoal(name: "Trip", target: 6000, saved: 2300, symbol: "airplane"))
        ctx.insert(RecurringItem(title: "Internet", amount: 119.9, kind: .expense, category: .bills, dayOfMonth: 10))
        return container
    }()
}
