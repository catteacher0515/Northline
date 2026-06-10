import SwiftUI

struct TimeInvestmentDashboardView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            totalsCard
            sessionCard

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .sheet(isPresented: $viewModel.isPresentingEndSessionSheet) {
            EndSessionSheet(
                onCancel: {
                    viewModel.cancelEndSession()
                },
                onConfirm: { draft in
                    viewModel.completeSession(using: draft)
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间投入")
                .font(.largeTitle.weight(.semibold))
            Text("开始时零阻力，结束时必须裁决。")
                .foregroundStyle(.secondary)
        }
    }

    private var totalsCard: some View {
        HStack(spacing: 12) {
            MetricPill(
                title: "今日生产",
                value: DurationFormatter.formatted(viewModel.todayTotals.productionSeconds)
            )
            MetricPill(
                title: "今日消费",
                value: DurationFormatter.formatted(viewModel.todayTotals.consumptionSeconds)
            )

            Spacer(minLength: 0)
        }
    }

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.isSessionRunning ? "进行中" : "未开始")
                .font(.headline)

            if viewModel.isSessionRunning {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已投入 \(DurationFormatter.formatted(viewModel.elapsedSeconds(now: context.date)))")
                            .font(.title2.weight(.semibold))
                        Text("默认参考时长 \(DurationFormatter.formatted(viewModel.referenceDurationSeconds))")
                            .foregroundStyle(.secondary)
                    }
                }

                Button("结束") {
                    viewModel.requestEndSession()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("点击开始即可进入静默计时。")
                    .foregroundStyle(.secondary)

                Button("开始") {
                    viewModel.startSession()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
