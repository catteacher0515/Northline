import SwiftUI

struct StressManagementModuleView: View {
    @ObservedObject var viewModel: StressManagementViewModel

    var body: some View {
        Group {
            switch viewModel.page {
            case .home:
                StressManagementHomeView(viewModel: viewModel)
            case .resetChecklist:
                StressResetChecklistView(viewModel: viewModel)
            case .resetResult:
                StressResetResultView(viewModel: viewModel)
            case .measurement:
                StressMeasurementView(viewModel: viewModel)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
    }
}
