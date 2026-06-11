import AppKit
import Combine
import Foundation

enum AppModule: String, CaseIterable, Identifiable {
    case timeInvestment
    case stressManagement
    case goalClarity

    var id: String { rawValue }
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedModule: AppModule = .timeInvestment
    @Published var settings: AppSettings {
        didSet {
            LocalJSONStore.save(settings, to: Self.settingsFileName)
            timeInvestmentViewModel.updateReferenceDurationSeconds(settings.referenceDurationSeconds)
        }
    }

    let timeInvestmentViewModel: TimeInvestmentViewModel
    let stressManagementViewModel: StressManagementViewModel

    private let hotkeyMonitor = GlobalHotkeyMonitor()
    private static let settingsFileName = "settings.json"

    init() {
        let settings = LocalJSONStore.load(AppSettings.self, from: Self.settingsFileName) ?? .default
        self.settings = settings
        self.timeInvestmentViewModel = TimeInvestmentViewModel(
            referenceDurationSeconds: settings.referenceDurationSeconds
        )
        self.stressManagementViewModel = StressManagementViewModel()
    }

    func startHotkeyMonitoring() {
        hotkeyMonitor.start(
            shortcutProvider: { [weak self] in
                self?.settings.startEndShortcut ?? AppSettings.default.startEndShortcut
            },
            action: { [weak self] in
                self?.handleStartEndShortcut()
            }
        )
    }

    func updateStartEndShortcut(_ shortcut: KeyboardShortcut) {
        settings.startEndShortcut = shortcut
    }

    private func handleStartEndShortcut() {
        selectedModule = .timeInvestment

        if timeInvestmentViewModel.isSessionRunning {
            timeInvestmentViewModel.requestEndSession()
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }
        } else {
            timeInvestmentViewModel.startSession()
        }
    }
}
