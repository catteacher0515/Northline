import AppKit
import Foundation

@MainActor
final class GlobalHotkeyMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var action: (() -> Void)?
    private var shortcutProvider: (() -> KeyboardShortcut)?

    func start(shortcutProvider: @escaping () -> KeyboardShortcut, action: @escaping () -> Void) {
        self.shortcutProvider = shortcutProvider
        self.action = action

        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handle(event)
            }
        }

        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                if self.handle(event) {
                    return nil
                }
                return event
            }
        }
    }

    @discardableResult
    private func handle(_ event: NSEvent) -> Bool {
        guard let shortcut = shortcutProvider?(), shortcut.matches(event) else {
            return false
        }
        action?()
        return true
    }
}
