import SwiftUI
import SwiftData

struct EntriesView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all, expense, income
        var id: String { rawValue }
        var name: String {
            switch self {
            case .all: String(localized: "All")
            case .expense: String(localized: "Expenses")
            case .income: String(localized: "Income")
            }
        }
    }

    @Environment(\.modelContext) private var context
    @Query(sort: \FinanceEntry.date, order: .reverse) private var entries: [FinanceEntry]

    @State private var month = Date.now.startOfMonth
    @State private var filter: Filter = .all
    @State private var search = ""
    @State private var editing: FinanceEntry?
    @State private var showingAdd = false

    private var filtered: [FinanceEntry] {
        entries.inMonth(month).filter { entry in
            switch filter {
            case .all: break
            case .expense: if entry.kind != .expense { return false }
            case .income: if entry.kind != .income { return false }
            }
            guard !search.isEmpty else { return true }
            return entry.title.localizedCaseInsensitiveContains(search)
                || entry.category.name.localizedCaseInsensitiveContains(search)
                || entry.note.localizedCaseInsensitiveContains(search)
        }
    }

    struct DayGroup: Identifiable {
        let day: Date
        let entries: [FinanceEntry]
        var id: Date { day }
    }

    private var days: [DayGroup] {
        let groups = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { DayGroup(day: $0, entries: groups[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthSwitcher(month: $month)
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Total")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(filtered.balance.currencyText)
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(filtered.balance >= 0 ? Color.green : Color.red)
                    }
                }

                if filtered.isEmpty {
                    ContentUnavailableView(search.isEmpty ? LocalizedStringKey("No transactions") : LocalizedStringKey("No results"),
                                           systemImage: search.isEmpty ? "tray" : "magnifyingglass",
                                           description: Text(search.isEmpty
                                                             ? LocalizedStringKey("Tap + to add your first transaction.")
                                                             : LocalizedStringKey("Try searching for another word.")))
                        .listRowBackground(Color.clear)
                }

                ForEach(days) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            Button { editing = entry } label: {
                                EntryRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) {
                                    context.delete(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            Spacer()
                            Text(group.entries.balance.currencyText)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search transactions")
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .accessibilityLabel("Add transaction")
                }
            }
            .sheet(isPresented: $showingAdd) { EntryFormView() }
            .sheet(item: $editing) { EntryFormView(entry: $0) }
        }
    }
}

#Preview {
    EntriesView()
        .modelContainer(Persistence.preview)
}
