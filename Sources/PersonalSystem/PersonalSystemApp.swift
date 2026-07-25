import SwiftUI

@main
struct PersonalSystemApp: App {
    @StateObject private var appState = AppState()

    init() {
        if CommandLine.arguments.contains("--self-check") {
            TimeInvestmentSelfCheck.runAndExit()
        }
    }

    var body: some Scene {
        WindowGroup("Time Mate") {
            AppCoordinator()
                .environmentObject(appState)
                .task {
                    appState.startHotkeyMonitoring()
                }
        }
        .defaultSize(width: 390, height: 650)
        .windowResizability(.contentSize)

        MenuBarExtra {
            TimeInvestmentMenuBarView(viewModel: appState.timeInvestmentViewModel, viewMode: .constant(.record))
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
        Text(viewModel.isSessionRunning ? "TM ●" : "TM ○")
            .font(.system(size: 12, weight: .bold, design: .rounded))
    }
}
