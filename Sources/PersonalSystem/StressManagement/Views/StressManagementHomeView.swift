import SwiftUI

struct StressManagementHomeView: View {
    @ObservedObject var viewModel: StressManagementViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("压力管理")
                    .font(.largeTitle.weight(.semibold))
                Text("把自己重新拉回可运转状态。")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                moduleCard(
                    title: "即时重置",
                    subtitle: "状态乱掉时，先做 10 题自查",
                    action: viewModel.startResetChecklist
                )

                moduleCard(
                    title: "压力测量",
                    subtitle: "记录过去一个月的压力状态",
                    action: viewModel.startMeasurement
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("最近记录")
                    .font(.headline)
                Text("即时重置：\(viewModel.latestResetSummary)")
                Text("压力测量：\(viewModel.latestMeasurementSummary)")
            }

            Spacer(minLength: 0)
        }
    }

    private func moduleCard(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}
