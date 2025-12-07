import Foundation

protocol PreferencesServiceProtocol {
    func loadTimezones() -> [WorldClockEntry]
    func saveTimezones(_ timezones: [WorldClockEntry])
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
}

final class PreferencesService: PreferencesServiceProtocol {
    private let userDefaults: UserDefaults
    private let timezonesKey = "worldclock.timezones"
    private let settingsKey = "worldclock.settings"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadTimezones() -> [WorldClockEntry] {
        guard let data = userDefaults.data(forKey: timezonesKey),
              let timezones = try? JSONDecoder().decode([WorldClockEntry].self, from: data) else {
            return WorldClockEntry.defaultTimezones
        }
        return timezones
    }

    func saveTimezones(_ timezones: [WorldClockEntry]) {
        if let data = try? JSONEncoder().encode(timezones) {
            userDefaults.set(data, forKey: timezonesKey)
        }
    }

    func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
}
