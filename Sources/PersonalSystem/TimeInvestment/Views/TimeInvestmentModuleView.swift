import SwiftUI

struct TimeInvestmentModuleView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("时间投入")
                    .font(.largeTitle.weight(.semibold))

                Text(viewModel.selectedTab == .record ? "开始、结束、即时裁决" : "看总账、趋势和最近产出")
                    .foregroundStyle(.secondary)

                Picker("页面", selection: $viewModel.selectedTab) {
                    ForEach(TimeInvestmentTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch viewModel.selectedTab {
            case .record:
                TimeInvestmentRecordView(viewModel: viewModel)
            case .review:
                TimeInvestmentReviewView(viewModel: viewModel)
            }
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
}
