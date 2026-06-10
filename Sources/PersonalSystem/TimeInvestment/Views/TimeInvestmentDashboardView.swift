import SwiftUI

struct TimeInvestmentDashboardView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        TimeInvestmentModuleView(viewModel: viewModel)
    }
}
