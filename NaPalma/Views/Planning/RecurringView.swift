import SwiftUI
import SwiftData

/// Fixed monthly bills and incomes (rent, salary, subscriptions) with reminders.
struct RecurringView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RecurringItem.dayOfMonth) private var items: [RecurringItem]

    @State private var showingAdd = false
    @State private var editing: RecurringItem?

    private var monthlyExpenses: Double {
        items.filter { $0.isActive && $0.kind == .expense }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView("No fixed bills yet",
                                       systemImage: "repeat",
                                       description: Text("Add rent, salary or subscriptions once. They'll be recorded every month and you'll get a reminder before bills are due."))
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(items) { item in
                        Button { editing = item } label: {
                            RecurringRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                BillReminders.cancel(item)
                                context.delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } footer: {
                    Text("Fixed expenses per month: \(monthlyExpenses.currencyText)")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
                .accessibilityLabel("Add fixed bill")
            }
        }
        .sheet(isPresented: $showingAdd) { RecurringFormView() }
        .sheet(item: $editing) { RecurringFormView(item: $0) }
    }
}

struct RecurringRow: View {
    let item: RecurringItem

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: item.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle)
                    .font(.body.weight(.medium))
                HStack(spacing: 4) {
                    Text("Every month on day \(item.dayOfMonth)")
                    if item.remind && item.kind == .expense {
                        Image(systemName: "bell.fill")
                    }
                    if !item.isActive {
                        Text("· Paused")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text((item.kind == .income ? "+ " : "− ") + item.amount.currencyText)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(item.kind == .income ? Color.green : Color.primary)
        }
        .opacity(item.isActive ? 1 : 0.5)
        .contentShape(Rectangle())
    }
}

struct RecurringFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let item: RecurringItem?

    @State private var kind: EntryKind
    @State private var title: String
    @State private var amount: Double?
    @State private var category: EntryCategory
    @State private var day: Int
    @State private var startDate: Date
    @State private var remind: Bool
    @State private var remindDaysBefore: Int
    @State private var isActive: Bool
    @FocusState private var focused: Bool

    init(item: RecurringItem? = nil) {
        self.item = item
        let initialKind = item?.kind ?? .expense
        _kind = State(initialValue: initialKind)
        _title = State(initialValue: item?.title ?? "")
        _amount = State(initialValue: item?.amount)
        _category = State(initialValue: item?.category ?? .bills)
        _day = State(initialValue: item?.dayOfMonth ?? Calendar.current.component(.day, from: .now))
        _startDate = State(initialValue: item?.startDate ?? .now)
        _remind = State(initialValue: item?.remind ?? true)
        _remindDaysBefore = State(initialValue: item?.remindDaysBefore ?? 1)
        _isActive = State(initialValue: item?.isActive ?? true)
    }

    private var canSave: Bool { (amount ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(EntryKind.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                    AmountField(amount: $amount, focus: $focused)
                    TextField("Name (e.g. Rent, Netflix)", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(EntryCategory.all(for: kind)) { category in
                            Label(category.name, systemImage: category.symbol).tag(category)
                        }
                    }
                }

                Section {
                    Picker("Day of the month", selection: $day) {
                        ForEach(1...31, id: \.self) { value in
                            Text(verbatim: "\(value)").tag(value)
                        }
                    }
                    DatePicker("Starts on", selection: $startDate, displayedComponents: .date)
                } footer: {
                    Text("The transaction is recorded automatically on this day every month.")
                }

                if kind == .expense {
                    Section {
                        Toggle("Remind me", isOn: $remind.animation())
                        if remind {
                            Picker("When", selection: $remindDaysBefore) {
                                Text("On the due day").tag(0)
                                Text("1 day before").tag(1)
                                Text("3 days before").tag(3)
                                Text("1 week before").tag(7)
                            }
                        }
                    } footer: {
                        Text("You'll get a notification at 9:00.")
                    }
                }

                if item != nil {
                    Section {
                        Toggle("Active", isOn: $isActive)
                    }
                }
            }
            .navigationTitle(item == nil ? String(localized: "New fixed bill") : String(localized: "Edit fixed bill"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                }
            }
            .onChange(of: kind) { _, newKind in
                if category.kind != newKind {
                    category = newKind == .expense ? .bills : .salary
                }
            }
        }
    }

    private func save() {
        guard let amount, amount > 0 else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let target: RecurringItem
        if let item {
            item.kind = kind
            item.title = trimmed
            item.amount = amount
            item.category = category
            item.dayOfMonth = day
            item.startDate = startDate
            item.remind = remind
            item.remindDaysBefore = remindDaysBefore
            item.isActive = isActive
            target = item
        } else {
            target = RecurringItem(title: trimmed, amount: amount, kind: kind, category: category,
                                   dayOfMonth: day, startDate: startDate,
                                   remind: remind, remindDaysBefore: remindDaysBefore)
            context.insert(target)
        }
        try? context.save()
        RecurrenceEngine.run(in: context)

        if target.remind && target.kind == .expense {
            Task {
                await BillReminders.requestAuthorization()
                BillReminders.schedule(target)
            }
        } else {
            BillReminders.cancel(target)
        }
        dismiss()
    }
}
