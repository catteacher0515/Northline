import Charts
import SwiftUI

struct ReviewDailyTrendChart: View {
    let rows: [ReviewDayRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("按天趋势")
                .font(.headline)

            Chart {
                ForEach(rows) { row in
                    BarMark(
                        x: .value("日期", row.date, unit: .day),
                        y: .value("生产", row.productionSeconds)
                    )
                    .foregroundStyle(.green)

                    BarMark(
                        x: .value("日期", row.date, unit: .day),
                        y: .value("消费", row.consumptionSeconds)
                    )
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 240)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
