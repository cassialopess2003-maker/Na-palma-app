import Foundation

/// Currency follows the iPhone's region settings.
enum Currency {
    static var code: String { Locale.current.currency?.identifier ?? "USD" }
}

extension Double {
    var currencyText: String {
        formatted(.currency(code: Currency.code))
    }

    var shortCurrencyText: String {
        formatted(.currency(code: Currency.code).precision(.fractionLength(0)))
    }

    var percentText: String {
        formatted(.percent.precision(.fractionLength(0)))
    }
}

extension Date {
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    var isCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: .now, toGranularity: .month)
    }

    var monthTitle: String {
        let text = formatted(.dateTime.month(.wide).year())
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
