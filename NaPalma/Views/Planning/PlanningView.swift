import SwiftUI

struct PlanningView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case budgets, goals, bills
        var id: String { rawValue }
        var name: String {
            switch self {
            case .budgets: String(localized: "Budgets")
            case .goals: String(localized: "Goals")
            case .bills: String(localized: "Fixed bills")
            }
        }
    }

    @State private var tab: Tab = .budgets

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.name).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                switch tab {
                case .budgets: BudgetsView()
                case .goals: GoalsView()
                case .bills: RecurringView()
                }
            }
            .screenBackground()
            .navigationTitle("Planning")
        }
    }
}
