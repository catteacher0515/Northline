import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Toggle("开机启动", isOn: $appState.launchAtLoginEnabled)
        }
        .padding()
        .frame(width: 360, height: 180)
    }
}
