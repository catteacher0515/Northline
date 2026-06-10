import SwiftUI

@main
struct PersonalSystemApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("Personal System") {
            AppCoordinator()
                .environmentObject(appState)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
