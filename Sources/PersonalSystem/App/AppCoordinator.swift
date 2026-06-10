import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ContainerHomeView(selectedModuleID: appState.selectedModuleID)
    }
}
