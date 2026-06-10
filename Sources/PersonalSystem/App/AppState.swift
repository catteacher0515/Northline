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
    @Published var launchAtLoginEnabled: Bool = false

    let timeInvestmentViewModel = TimeInvestmentViewModel()
}
