import Combine
import Foundation

final class AppState: ObservableObject {
    @Published var selectedModuleID: String = "time-investment"
    @Published var launchAtLoginEnabled: Bool = false
}
