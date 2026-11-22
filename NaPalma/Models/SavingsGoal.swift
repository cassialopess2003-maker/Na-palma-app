import Foundation
import SwiftData

@Model
final class SavingsGoal {
    var name: String = ""
    var target: Double = 0
    var saved: Double = 0
    var symbol: String = "star.fill"
    var deadline: Date?
    var createdAt: Date = Date.now

    init(name: String, target: Double, saved: Double = 0, symbol: String = "star.fill", deadline: Date? = nil) {
        self.name = name
        self.target = target
        self.saved = saved
        self.symbol = symbol
        self.deadline = deadline
        self.createdAt = .now
    }

    var progress: Double { target > 0 ? min(saved / target, 1) : 0 }
    var remaining: Double { max(target - saved, 0) }
    var isCompleted: Bool { target > 0 && saved >= target }

    static let symbols = [
        "star.fill", "airplane", "car.fill", "house.fill", "graduationcap.fill",
        "gift.fill", "heart.fill", "iphone", "banknote.fill", "beach.umbrella.fill",
        "bicycle", "pawprint.fill"
    ]
}
