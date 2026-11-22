import SwiftUI

enum EntryKind: String, CaseIterable, Identifiable, Codable {
    case expense
    case income

    var id: String { rawValue }

    var name: String {
        switch self {
        case .expense: String(localized: "Expense")
        case .income: String(localized: "Income")
        }
    }

    var color: Color {
        switch self {
        case .expense: .red
        case .income: .green
        }
    }

    var symbol: String {
        switch self {
        case .expense: "arrow.down.circle.fill"
        case .income: "arrow.up.circle.fill"
        }
    }
}

enum EntryCategory: String, CaseIterable, Identifiable, Codable {
    // Expenses
    case food, groceries, transport, housing, bills, health, education
    case leisure, shopping, subscriptions, pets, travel, otherExpense
    // Income
    case salary, freelance, investments, gifts, otherIncome

    var id: String { rawValue }

    static func all(for kind: EntryKind) -> [EntryCategory] {
        allCases.filter { $0.kind == kind }
    }

    var kind: EntryKind {
        switch self {
        case .salary, .freelance, .investments, .gifts, .otherIncome: .income
        default: .expense
        }
    }

    var name: String {
        switch self {
        case .food: String(localized: "Restaurants")
        case .groceries: String(localized: "Groceries")
        case .transport: String(localized: "Transport")
        case .housing: String(localized: "Housing")
        case .bills: String(localized: "Bills")
        case .health: String(localized: "Health")
        case .education: String(localized: "Education")
        case .leisure: String(localized: "Leisure")
        case .shopping: String(localized: "Shopping")
        case .subscriptions: String(localized: "Subscriptions")
        case .pets: String(localized: "Pets")
        case .travel: String(localized: "Travel")
        case .otherExpense: String(localized: "Other")
        case .salary: String(localized: "Salary")
        case .freelance: String(localized: "Freelance")
        case .investments: String(localized: "Investments")
        case .gifts: String(localized: "Gifts")
        case .otherIncome: String(localized: "Other income")
        }
    }

    var symbol: String {
        switch self {
        case .food: "fork.knife"
        case .groceries: "cart.fill"
        case .transport: "car.fill"
        case .housing: "house.fill"
        case .bills: "doc.text.fill"
        case .health: "cross.case.fill"
        case .education: "graduationcap.fill"
        case .leisure: "gamecontroller.fill"
        case .shopping: "bag.fill"
        case .subscriptions: "play.rectangle.fill"
        case .pets: "pawprint.fill"
        case .travel: "airplane"
        case .otherExpense: "ellipsis.circle.fill"
        case .salary: "briefcase.fill"
        case .freelance: "laptopcomputer"
        case .investments: "chart.line.uptrend.xyaxis"
        case .gifts: "gift.fill"
        case .otherIncome: "plus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: .orange
        case .groceries: .green
        case .transport: .blue
        case .housing: .brown
        case .bills: .indigo
        case .health: .red
        case .education: .purple
        case .leisure: .pink
        case .shopping: .teal
        case .subscriptions: .cyan
        case .pets: .yellow
        case .travel: .mint
        case .otherExpense: .gray
        case .salary: .green
        case .freelance: .blue
        case .investments: .purple
        case .gifts: .pink
        case .otherIncome: .gray
        }
    }
}
