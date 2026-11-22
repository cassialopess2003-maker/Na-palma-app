import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \FinanceEntry.date, order: .reverse) private var entries: [FinanceEntry]
    @Query private var budgets: [Budget]
    @Query(filter: #Predicate<RecurringItem> { $0.isActive }) private var recurring: [RecurringItem]

    @State private var month = Date.now.startOfMonth
    @State private var newEntryKind: EntryKind?
    @State private var editing: FinanceEntry?

    private var monthEntries: [FinanceEntry] { entries.inMonth(month) }

    private var budgetAlerts: [BudgetStatus] {
        BudgetStatus.make(budgets: budgets, entries: entries, month: month)
            .filter { $0.budget.limit > 0 && $0.ratio >= 0.8 }
            .sorted { $0.ratio > $1.ratio }
    }

    private var upcomingBills: [RecurringItem] {
        let limit = Date.now.adding(days: 7)
        return recurring
            .filter { $0.kind == .expense && $0.nextDueDate() <= limit }
            .sorted { $0.nextDueDate() < $1.nextDueDate() }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthSwitcher(month: $month)

                    BalanceCard(balance: monthEntries.balance,
                                income: monthEntries.total(.income),
                                expense: monthEntries.total(.expense))

                    quickActions

                    if month.isCurrentMonth && !upcomingBills.isEmpty {
                        upcomingSection
                    }

                    if !budgetAlerts.isEmpty {
                        alertsSection
                    }

                    recentSection
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("Na Palma")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newEntryKind = .expense
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add transaction")
                }
            }
            .sheet(item: $newEntryKind) { kind in
                EntryFormView(kind: kind)
            }
            .sheet(item: $editing) { entry in
                EntryFormView(entry: entry)
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(title: "Expense", symbol: "minus", color: .red) {
                newEntryKind = .expense
            }
            QuickActionButton(title: "Income", symbol: "plus", color: .green) {
                newEntryKind = .income
            }
        }
    }

    private var upcomingSection: some View {
        Card {
            Label("Upcoming bills", systemImage: "bell.badge.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(upcomingBills) { bill in
                HStack(spacing: 12) {
                    CategoryIcon(category: bill.category, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bill.displayTitle).font(.subheadline.weight(.medium))
                        Text(bill.nextDueDate().formatted(.dateTime.weekday(.wide).day().month()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(bill.amount.currencyText)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
    }

    private var alertsSection: some View {
        Card {
            Label("Budget alerts", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(budgetAlerts) { item in
                let ratio = item.ratio
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        CategoryIcon(category: item.budget.category, size: 28)
                        Text(item.budget.category.name).font(.subheadline.weight(.medium))
                        Spacer()
                        Text(ratio >= 1
                             ? String(localized: "Over budget")
                             : String(localized: "\(ratio.percentText) used"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(budgetTint(ratio))
                    }
                    ProgressView(value: min(ratio, 1))
                        .tint(budgetTint(ratio))
                }
            }
        }
    }

    private var recentSection: some View {
        Card {
            Text("Recent transactions")
                .font(.headline)
            if monthEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No transactions this month")
                        .font(.subheadline.weight(.medium))
                    Text("Tap Expense or Income to add your first one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(monthEntries.prefix(6)) { entry in
                    Button { editing = entry } label: {
                        EntryRow(entry: entry, showsDate: true)
                    }
                    .buttonStyle(.plain)
                    if entry.persistentModelID != monthEntries.prefix(6).last?.persistentModelID {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
    }
}

/// The big gradient card at the top of Home.
struct BalanceCard: View {
    let balance: Double
    let income: Double
    let expense: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance this month")
                    .font(.subheadline)
                    .opacity(0.85)
                Text(balance.currencyText)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            HStack(spacing: 12) {
                summary(title: "Income", value: income, symbol: "arrow.up.circle.fill")
                summary(title: "Expenses", value: expense, symbol: "arrow.down.circle.fill")
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private func summary(title: LocalizedStringKey, value: Double, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).font(.title3)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.caption).opacity(0.85)
                Text(value.currencyText)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct QuickActionButton: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: symbol)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color, in: Circle())
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .modelContainer(Persistence.preview)
}
