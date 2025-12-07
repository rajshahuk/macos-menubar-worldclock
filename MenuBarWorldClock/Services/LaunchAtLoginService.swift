import Foundation
import ServiceManagement

protocol LaunchAtLoginServiceProtocol {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool)
}

final class LaunchAtLoginService: LaunchAtLoginServiceProtocol {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}
