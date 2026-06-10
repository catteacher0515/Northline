import SwiftUI

struct TimeInvestmentModuleView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker("页面", selection: $viewModel.selectedTab) {
                ForEach(TimeInvestmentTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

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
