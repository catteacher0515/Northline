import SwiftUI

struct TimeInvestmentMenuBarView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    @State private var classification: SessionClassification = .consumption
    @State private var productionNote = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            totals

            if viewModel.isSessionRunning {
                runningSessionSection
            } else {
                idleSessionSection
            }
        }
        .padding(16)
        .frame(width: 320)
        .onChange(of: viewModel.isSessionRunning) { _, isRunning in
            if isRunning == false {
                classification = .consumption
                productionNote = ""
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("时间投入")
                .font(.headline.weight(.semibold))
            Text(viewModel.isSessionRunning ? "运行中" : "未运行")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var totals: some View {
        HStack(spacing: 12) {
            MetricPill(
                title: "今日生产",
                value: DurationFormatter.formatted(viewModel.todayTotals.productionSeconds)
            )
            MetricPill(
                title: "今日消费",
                value: DurationFormatter.formatted(viewModel.todayTotals.consumptionSeconds)
            )
        }
    }

    @ViewBuilder
    private var runningSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 4) {
                    Text("已投入 \(DurationFormatter.formatted(viewModel.elapsedSeconds(now: context.date)))")
                        .font(.headline)
                    Text("默认参考时长 \(DurationFormatter.formatted(viewModel.referenceDurationSeconds))")
                        .foregroundStyle(.secondary)
                }
            }

            Picker("裁决", selection: $classification) {
                Text("消费").tag(SessionClassification.consumption)
                Text("生产").tag(SessionClassification.production)
            }
            .pickerStyle(.segmented)

            if classification == .production {
                EndSessionProductionForm(productionNote: $productionNote)
            }

            HStack {
                Button("重置") {
                    classification = .consumption
                    productionNote = ""
                }

                Spacer()

                Button("记录") {
                    confirmEndSession()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var idleSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("点击开始即可进入静默计时。")
                .foregroundStyle(.secondary)

            Button("开始 session") {
                viewModel.startSession()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func confirmEndSession() {
        switch classification {
        case .consumption:
            viewModel.completeSession(using: .consumption)
        case .production:
            viewModel.completeSession(using: .production(note: productionNote))
        }
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
