import SwiftUI

struct ReviewRangePicker: View {
    @Binding var selectedRange: ReviewRange

    var body: some View {
        HStack(spacing: 12) {
            rangeButton(title: "今天", range: .today)
            rangeButton(title: "本周", range: .week)
            rangeButton(title: "本月", range: .month)

            Button("自定义") {
                let calendar = Calendar.current
                let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
                let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
                selectedRange = .custom(start: start, end: end)
            }
            .buttonStyle(.bordered)
        }
    }

    private func rangeButton(title: String, range: ReviewRange) -> some View {
        Group {
            if selectedRange == range {
                Button(title) {
                    selectedRange = range
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(title) {
                    selectedRange = range
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
