import SwiftUI

/// Round colored icon used for categories everywhere in the app.
struct CategoryIcon: View {
    let category: EntryCategory
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(category.color)
            .frame(width: size, height: size)
            .background(category.color.opacity(0.15), in: Circle())
    }
}

/// "‹ November 2026 ›" selector.
struct MonthSwitcher: View {
    @Binding var month: Date

    var body: some View {
        HStack {
            Button {
                withAnimation { month = month.adding(months: -1).startOfMonth }
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Button {
                withAnimation { month = Date.now.startOfMonth }
            } label: {
                Text(month.monthTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .accessibilityHint("Go to current month")

            Spacer()

            Button {
                withAnimation { month = month.adding(months: 1).startOfMonth }
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Next month")
        }
        .fontWeight(.semibold)
    }
}

/// One line in the transactions lists.
struct EntryRow: View {
    let entry: FinanceEntry
    var showsDate = false

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: entry.category)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.displayTitle)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    if entry.recurringID != nil {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(showsDate
                     ? "\(entry.category.name) · \(entry.date.formatted(.dateTime.day().month(.abbreviated)))"
                     : entry.category.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text((entry.kind == .income ? "+ " : "− ") + entry.amount.currencyText)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(entry.kind == .income ? Color.green : Color.primary)
        }
        .contentShape(Rectangle())
    }
}

/// Grid of category bubbles for quick picking.
struct CategoryGrid: View {
    let kind: EntryKind
    @Binding var selection: EntryCategory

    private let columns = [GridItem(.adaptive(minimum: 70), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(EntryCategory.all(for: kind)) { category in
                Button {
                    selection = category
                } label: {
                    VStack(spacing: 6) {
                        CategoryIcon(category: category, size: 46)
                            .overlay {
                                if selection == category {
                                    Circle().strokeBorder(category.color, lineWidth: 2.5)
                                }
                            }
                        Text(category.name)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(selection == category ? Color.primary : Color.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == category ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

/// Large, friendly amount field.
struct AmountField: View {
    @Binding var amount: Double?
    var focus: FocusState<Bool>.Binding

    var body: some View {
        TextField("Amount", value: $amount, format: .currency(code: Currency.code))
            .keyboardType(.decimalPad)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .focused(focus)
    }
}

/// Rounded card container.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    /// Standard grouped background for scroll screens.
    func screenBackground() -> some View {
        background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

/// Tint used for budget progress: green → orange → red.
func budgetTint(_ ratio: Double) -> Color {
    ratio >= 1 ? .red : (ratio >= 0.8 ? .orange : .green)
}
