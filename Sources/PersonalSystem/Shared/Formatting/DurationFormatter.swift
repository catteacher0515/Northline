import Foundation

enum DurationFormatter {
    static func formatted(_ seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)
        let hours = clampedSeconds / 3_600
        let minutes = (clampedSeconds % 3_600) / 60
        let remainingSeconds = clampedSeconds % 60

        if hours > 0 {
            return "\(hours)时 \(minutes)分"
        }

        if minutes > 0 {
            return remainingSeconds == 0 ? "\(minutes)分" : "\(minutes)分 \(remainingSeconds)秒"
        }

        return "\(remainingSeconds)秒"
    }
}
