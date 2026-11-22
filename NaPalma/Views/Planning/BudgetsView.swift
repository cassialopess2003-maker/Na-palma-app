import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var context
    @Query private var budgets: [Budget]
    @Query private var entries: [FinanceEntry]

    @State private var showingAdd = false
    @State private var editing: Budget?

    private var statuses: [BudgetStatus] {
        BudgetStatus.make(budgets: budgets, entries: entries, month: .now)
            .sorted { $0.budget.category.name < $1.budget.category.name }
    }

    var body: some View {
        List {
            if statuses.isEmpty {
                ContentUnavailableView("No budgets yet",
                                       systemImage: "chart.bar.doc.horizontal",
                                       description: Text("Set a monthly limit for a category and we'll warn you when you get close."))
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(statuses) { status in
                        Button { editing = status.budget } label: {
                            BudgetRow(status: status)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                context.delete(status.budget)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(Date.now.monthTitle)
                } footer: {
                    Text("Budgets reset at the beginning of every month.")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
                .accessibilityLabel("Add budget")
            }
        }
        .sheet(isPresented: $showingAdd) { BudgetFormView(existing: budgets) }
        .sheet(item: $editing) { BudgetFormView(budget: $0, existing: budgets) }
    }
}

struct BudgetRow: View {
    let status: BudgetStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                CategoryIcon(category: status.budget.category, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.budget.category.name)
                        .font(.body.weight(.medium))
                    Text("\(status.spent.currencyText) of \(status.budget.limit.currencyText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(status.ratio.percentText)
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(budgetTint(status.ratio))
            }
            ProgressView(value: min(status.ratio, 1))
                .tint(budgetTint(status.ratio))
            Text(status.remaining >= 0
                 ? String(localized: "\(status.remaining.currencyText) left")
                 : String(localized: "\((-status.remaining).currencyText) over budget"))
                .font(.caption.weight(.medium))
                .foregroundStyle(status.remaining >= 0 ? Color.secondary : Color.red)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let budget: Budget?
    let existing: [Budget]

    @State private var category: EntryCategory
    @State private var limit: Double?
    @FocusState private var focused: Bool

    init(budget: Budget? = nil, existing: [Budget]) {
        self.budget = budget
        self.existing = existing
        let used = Set(existing.map(\.category))
        let firstFree = EntryCategory.all(for: .expense).first { !used.contains($0) } ?? .food
        _category = State(initialValue: budget?.category ?? firstFree)
        _limit = State(initialValue: budget?.limit)
    }

    private var available: [EntryCategory] {
        let used = Set(existing.filter { $0 !== budget }.map(\.category))
        return EntryCategory.all(for: .expense).filter { !used.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(available) { category in
                            Label(category.name, systemImage: category.symbol).tag(category)
                        }
                    }
                } footer: {
                    Text("Each category can have one budget.")
                }
                Section("Monthly limit") {
                    AmountField(amount: $limit, focus: $focused)
                }
            }
            .navigationTitle(budget == nil ? String(localized: "New budget") : String(localized: "Edit budget"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled((limit ?? 0) <= 0 || available.isEmpty)
                }
            }
            .onAppear { focused = budget == nil }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard let limit, limit > 0 else { return }
        if let budget {
            budget.category = category
            budget.limit = limit
        } else {
            context.insert(Budget(category: category, limit: limit))
        }
        dismiss()
    }
}
