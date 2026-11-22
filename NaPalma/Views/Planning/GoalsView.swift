import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavingsGoal.createdAt) private var goals: [SavingsGoal]

    @State private var showingAdd = false
    @State private var editing: SavingsGoal?
    @State private var depositing: SavingsGoal?

    var body: some View {
        List {
            if goals.isEmpty {
                ContentUnavailableView("No goals yet",
                                       systemImage: "target",
                                       description: Text("Create a goal like a trip or an emergency fund and track your progress."))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(goals) { goal in
                    GoalRow(goal: goal) { depositing = goal }
                        .contentShape(Rectangle())
                        .onTapGesture { editing = goal }
                        .swipeActions {
                            Button(role: .destructive) {
                                context.delete(goal)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
                .accessibilityLabel("Add goal")
            }
        }
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .sheet(item: $editing) { GoalFormView(goal: $0) }
        .sheet(item: $depositing) { GoalDepositView(goal: $0) }
    }
}

struct GoalRow: View {
    let goal: SavingsGoal
    let onDeposit: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: goal.progress)
                    .stroke(goal.isCompleted ? Color.green : Color.accentColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: goal.isCompleted ? "checkmark" : goal.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(goal.isCompleted ? Color.green : Color.accentColor)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.name)
                    .font(.body.weight(.semibold))
                Text("\(goal.saved.currencyText) of \(goal.target.currencyText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if goal.isCompleted {
                    Text("Goal reached! 🎉")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else if let deadline = goal.deadline {
                    Text("Until \(deadline.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onDeposit) {
                Image(systemName: "plus")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.15), in: Circle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Add money")
        }
        .padding(.vertical, 6)
    }
}

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let goal: SavingsGoal?

    @State private var name: String
    @State private var target: Double?
    @State private var saved: Double?
    @State private var symbol: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @FocusState private var focused: Bool

    init(goal: SavingsGoal? = nil) {
        self.goal = goal
        _name = State(initialValue: goal?.name ?? "")
        _target = State(initialValue: goal?.target)
        _saved = State(initialValue: goal?.saved)
        _symbol = State(initialValue: goal?.symbol ?? SavingsGoal.symbols[0])
        _hasDeadline = State(initialValue: goal?.deadline != nil)
        _deadline = State(initialValue: goal?.deadline ?? Date.now.adding(months: 6))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (target ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal name (e.g. Trip)", text: $name)
                    LabeledContent("Target") {
                        TextField("Target", value: $target, format: .currency(code: Currency.code))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focused)
                    }
                    LabeledContent("Already saved") {
                        TextField("Already saved", value: $saved, format: .currency(code: Currency.code))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focused)
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(SavingsGoal.symbols, id: \.self) { item in
                            Button { symbol = item } label: {
                                Image(systemName: item)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(symbol == item ? Color.white : Color.accentColor)
                                    .background(symbol == item ? Color.accentColor : Color.accentColor.opacity(0.12),
                                                in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Set a deadline", isOn: $hasDeadline.animation())
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, in: Date.now..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(goal == nil ? String(localized: "New goal") : String(localized: "Edit goal"))
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
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let target, target > 0 else { return }
        if let goal {
            goal.name = trimmed
            goal.target = target
            goal.saved = saved ?? 0
            goal.symbol = symbol
            goal.deadline = hasDeadline ? deadline : nil
        } else {
            context.insert(SavingsGoal(name: trimmed, target: target, saved: saved ?? 0,
                                       symbol: symbol, deadline: hasDeadline ? deadline : nil))
        }
        dismiss()
    }
}

struct GoalDepositView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: SavingsGoal

    @State private var amount: Double?
    @State private var withdraw = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Action", selection: $withdraw) {
                        Text("Add money").tag(false)
                        Text("Withdraw").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                    AmountField(amount: $amount, focus: $focused)
                } footer: {
                    Text("Saved so far: \(goal.saved.currencyText)")
                }
            }
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let value = amount ?? 0
                        goal.saved = max(goal.saved + (withdraw ? -value : value), 0)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled((amount ?? 0) <= 0)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}
