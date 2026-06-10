import SwiftUI

@main
struct PersonalSystemApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("Personal System") {
            AppCoordinator()
                .environmentObject(appState)
        }

        MenuBarExtra {
            TimeInvestmentMenuBarView(viewModel: appState.timeInvestmentViewModel)
        } label: {
            TimeInvestmentMenuBarLabel(viewModel: appState.timeInvestmentViewModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

private struct TimeInvestmentMenuBarLabel: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        Text(viewModel.isSessionRunning ? "●" : "○")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
    }
}
