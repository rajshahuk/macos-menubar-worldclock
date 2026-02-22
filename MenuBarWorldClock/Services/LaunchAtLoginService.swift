import Foundation
import ServiceManagement

protocol LaunchAtLoginServiceProtocol {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

final class LaunchAtLoginService: LaunchAtLoginServiceProtocol {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
