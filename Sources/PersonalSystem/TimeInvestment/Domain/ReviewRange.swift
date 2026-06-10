import Foundation

enum ReviewRange: Equatable {
    case today
    case week
    case month
    case custom(start: Date, end: Date)

    func dateInterval(now: Date, calendar: Calendar = .current) -> DateInterval {
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return DateInterval(start: start, end: end)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, end: now)
        case .month:
            return calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, end: now)
        case let .custom(start, end):
            return DateInterval(start: start, end: end)
        }
    }

    var title: String {
        switch self {
        case .today:
            return "今天"
        case .week:
            return "本周"
        case .month:
            return "本月"
        case .custom:
            return "自定义"
        }
    }
}
