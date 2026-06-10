import SwiftUI

struct ReviewSummaryCards: View {
    let summary: ReviewSummary

    var body: some View {
        HStack(spacing: 12) {
            ReviewMetricCard(title: "总投入", value: DurationFormatter.formatted(summary.totalSeconds))
            ReviewMetricCard(title: "生产", value: DurationFormatter.formatted(summary.productionSeconds))
            ReviewMetricCard(title: "消费", value: DurationFormatter.formatted(summary.consumptionSeconds))
            ReviewMetricCard(title: "生产占比", value: "\(Int(summary.productionRatio * 100))%")
            Spacer(minLength: 0)
        }
    }
}

private struct ReviewMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: 180, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
