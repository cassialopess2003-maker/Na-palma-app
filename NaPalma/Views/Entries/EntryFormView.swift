import SwiftUI
import SwiftData

/// Add or edit an income/expense.
struct EntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let entry: FinanceEntry?

    @State private var kind: EntryKind
    @State private var amount: Double?
    @State private var title: String
    @State private var category: EntryCategory
    @State private var date: Date
    @State private var note: String
    @State private var confirmDelete = false
    @FocusState private var amountFocused: Bool

    init(entry: FinanceEntry? = nil, kind: EntryKind = .expense) {
        self.entry = entry
        let initialKind = entry?.kind ?? kind
        _kind = State(initialValue: initialKind)
        _amount = State(initialValue: entry?.amount)
        _title = State(initialValue: entry?.title ?? "")
        _category = State(initialValue: entry?.category ?? EntryCategory.all(for: initialKind)[0])
        _date = State(initialValue: entry?.date ?? .now)
        _note = State(initialValue: entry?.note ?? "")
    }

    private var canSave: Bool { (amount ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(EntryKind.allCases) { kind in
                            Text(kind.name).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)

                    AmountField(amount: $amount, focus: $amountFocused)
                        .foregroundStyle(kind == .income ? Color.green : Color.primary)

                    TextField("Description (optional)", text: $title)
                }

                Section("Category") {
                    CategoryGrid(kind: kind, selection: $category)
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }

                if entry != nil {
                    Section {
                        Button("Delete transaction", role: .destructive) {
                            confirmDelete = true
                        }
                    }
                }
            }
            .navigationTitle(entry == nil ? String(localized: "New transaction") : String(localized: "Edit transaction"))
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
                    Button("Done") { amountFocused = false }
                }
            }
            .onChange(of: kind) { _, newKind in
                if category.kind != newKind {
                    category = EntryCategory.all(for: newKind)[0]
                }
            }
            .onAppear {
                if entry == nil { amountFocused = true }
            }
            .confirmationDialog("Delete this transaction?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let entry { context.delete(entry) }
                    dismiss()
                }
            }
        }
    }

    private func save() {
        guard let amount, amount > 0 else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let entry {
            entry.kind = kind
            entry.amount = amount
            entry.title = trimmed
            entry.category = category
            entry.date = date
            entry.note = note
        } else {
            context.insert(FinanceEntry(title: trimmed, amount: amount, date: date,
                                        kind: kind, category: category, note: note))
        }
        dismiss()
    }
}

#Preview {
    EntryFormView()
        .modelContainer(Persistence.preview)
}
