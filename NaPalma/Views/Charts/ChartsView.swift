import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query(sort: \FinanceEntry.date, order: .reverse) private var entries: [FinanceEntry]

    @State private var month = Date.now.startOfMonth
    @State private var kind: EntryKind = .expense

    struct CategoryTotal: Identifiable {
        let category: EntryCategory
        let total: Double
        var id: EntryCategory { category }
    }

    struct MonthTotal: Identifiable {
        let month: Date
        let kind: EntryKind
        let total: Double
        var id: String { "\(month.timeIntervalSince1970)-\(kind.rawValue)" }
    }

    private var slices: [CategoryTotal] {
        let items = entries.inMonth(month).filter { $0.kind == kind }
        let grouped = Dictionary(grouping: items, by: \.category)
        return grouped
            .map { CategoryTotal(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    private var sliceTotal: Double { slices.reduce(0) { $0 + $1.total } }

    private var lastSixMonths: [MonthTotal] {
        (0..<6).reversed().flatMap { offset -> [MonthTotal] in
            let m = month.adding(months: -offset).startOfMonth
            let items = entries.inMonth(m)
            return [
                MonthTotal(month: m, kind: .income, total: items.total(.income)),
                MonthTotal(month: m, kind: .expense, total: items.total(.expense))
            ]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthSwitcher(month: $month)
                    donutCard
                    barsCard
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("Charts")
        }
    }

    private var donutCard: some View {
        Card {
            Picker("Type", selection: $kind) {
                ForEach(EntryKind.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.segmented)

            if slices.isEmpty {
                ContentUnavailableView("No data this month",
                                       systemImage: "chart.pie",
                                       description: Text("Your categories will show up here."))
            } else {
                ZStack {
                    Chart(slices) { slice in
                        SectorMark(angle: .value("Amount", slice.total),
                                   innerRadius: .ratio(0.62),
                                   angularInset: 1.5)
                            .cornerRadius(5)
                            .foregroundStyle(slice.category.color)
                    }
                    .chartLegend(.hidden)
                    .frame(height: 230)

                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(sliceTotal.currencyText)
                            .font(.title3.bold())
                            .monospacedDigit()
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 140)
                }
                .padding(.vertical, 8)

                VStack(spacing: 10) {
                    ForEach(slices) { slice in
                        HStack(spacing: 10) {
                            CategoryIcon(category: slice.category, size: 30)
                            Text(slice.category.name)
                                .font(.subheadline)
                            Spacer()
                            Text((slice.total / max(sliceTotal, 0.01)).percentText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(slice.total.currencyText)
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }

    private var barsCard: some View {
        Card {
            Text("Last 6 months")
                .font(.headline)
            Chart(lastSixMonths) { item in
                BarMark(x: .value("Month", item.month, unit: .month),
                        y: .value("Amount", item.total))
                    .foregroundStyle(by: .value("Type", item.kind.name))
                    .position(by: .value("Type", item.kind.name))
                    .cornerRadius(4)
            }
            .chartForegroundStyleScale(domain: [EntryKind.income.name, EntryKind.expense.name],
                                       range: [Color.green, Color.red])
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.shortCurrencyText)
                        }
                    }
                }
            }
            .frame(height: 220)
        }
    }
}

#Preview {
    ChartsView()
        .modelContainer(Persistence.preview)
}
