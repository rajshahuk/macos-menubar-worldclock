import Foundation

enum DisplayMode: String, Codable, CaseIterable {
    case flagOnly = "flag"
    case locationOnly = "location"
    case both = "both"

    var description: String {
        switch self {
        case .flagOnly: return "Flag only"
        case .locationOnly: return "Location only"
        case .both: return "Flag and Location"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var use24HourFormat: Bool
    var showSeconds: Bool
    var showTimezoneOffset: Bool
    var launchAtLogin: Bool
    var primaryTimezoneId: UUID?
    var displayMode: DisplayMode

    init(use24HourFormat: Bool = true, showSeconds: Bool = true, showTimezoneOffset: Bool = false, launchAtLogin: Bool = false, primaryTimezoneId: UUID? = nil, displayMode: DisplayMode = .both) {
        self.use24HourFormat = use24HourFormat
        self.showSeconds = showSeconds
        self.showTimezoneOffset = showTimezoneOffset
        self.launchAtLogin = launchAtLogin
        self.primaryTimezoneId = primaryTimezoneId
        self.displayMode = displayMode
    }

    static let `default` = AppSettings()
}
