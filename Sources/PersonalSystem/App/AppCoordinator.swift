import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ContainerHomeView(
            selectedModule: appState.selectedModule,
            onSelectModule: { module in
                appState.selectedModule = module
            },
            timeInvestmentViewModel: appState.timeInvestmentViewModel,
            stressManagementViewModel: appState.stressManagementViewModel
        )
    }
}
