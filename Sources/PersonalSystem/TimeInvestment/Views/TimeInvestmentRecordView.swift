import SwiftUI

struct TimeInvestmentRecordView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            totalsCard
            historyCard
            sessionCard

            Spacer(minLength: 0)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间投入")
                .font(.largeTitle.weight(.semibold))
            Text("开始时零阻力，结束后补任务、分类和主观分数。")
                .foregroundStyle(.secondary)
        }
    }

    private var totalsCard: some View {
        HStack(spacing: 12) {
            RecordMetricPill(
                title: "学习/工作",
                value: DurationFormatter.formatted(viewModel.todayTotals.productionSeconds)
            )
            RecordMetricPill(
                title: "其他记录",
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

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("持久化状态")
                .font(.headline)

            Text("历史记录数：\(viewModel.historySummary.totalCount)")

            if let latestEndAt = viewModel.historySummary.latestEndAt {
                Text("最近记录时间：\(latestEndAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(.secondary)
            } else {
                Text("最近记录时间：暂无")
                    .foregroundStyle(.secondary)
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

private struct RecordMetricPill: View {
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
