import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var timezones: [WorldClockEntry] = []
    @Published var settings: AppSettings = .default
    @Published var currentDate: Date = Date()

    private let preferencesService: PreferencesServiceProtocol
    private let timezoneService: TimezoneServiceProtocol
    private let launchAtLoginService: LaunchAtLoginServiceProtocol
    private var timerCancellable: AnyCancellable?

    var primaryTimezone: WorldClockEntry? {
        if let primaryId = settings.primaryTimezoneId {
            return timezones.first { $0.id == primaryId }
        }
        return timezones.first
    }

    init(
        preferencesService: PreferencesServiceProtocol = PreferencesService(),
        timezoneService: TimezoneServiceProtocol = TimezoneService(),
        launchAtLoginService: LaunchAtLoginServiceProtocol = LaunchAtLoginService()
    ) {
        self.preferencesService = preferencesService
        self.timezoneService = timezoneService
        self.launchAtLoginService = launchAtLoginService

        loadData()
        startTimer()
    }

    private func loadData() {
        timezones = preferencesService.loadTimezones()
        settings = preferencesService.loadSettings()

        // Remove duplicates (keep first occurrence)
        var seenIdentifiers = Set<String>()
        let deduplicatedTimezones = timezones.filter { entry in
            if seenIdentifiers.contains(entry.timezoneIdentifier) {
                return false
            }
            seenIdentifiers.insert(entry.timezoneIdentifier)
            return true
        }
        if deduplicatedTimezones.count != timezones.count {
            timezones = deduplicatedTimezones
            saveTimezones()
        }

        // Ensure primary timezone is valid
        if let primaryId = settings.primaryTimezoneId,
           !timezones.contains(where: { $0.id == primaryId }) {
            settings.primaryTimezoneId = timezones.first?.id
            saveSettings()
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentDate = Date()
            }
    }

    func formattedTime(for entry: WorldClockEntry) -> String {
        timezoneService.formattedTime(for: entry, use24Hour: settings.use24HourFormat, showSeconds: settings.showSeconds, date: currentDate)
    }

    func dayOffsetString(for entry: WorldClockEntry) -> String? {
        let offset = timezoneService.dayOffset(for: entry, date: currentDate)
        switch offset {
        case 1: return "+1 day"
        case -1: return "-1 day"
        default: return nil
        }
    }

    func setPrimaryTimezone(_ entry: WorldClockEntry) {
        settings.primaryTimezoneId = entry.id
        saveSettings()
    }

    func isPrimary(_ entry: WorldClockEntry) -> Bool {
        if let primaryId = settings.primaryTimezoneId {
            return entry.id == primaryId
        }
        return timezones.first?.id == entry.id
    }

    func addTimezone(_ entry: WorldClockEntry) {
        timezones.append(entry)
        saveTimezones()
    }

    func removeTimezone(_ entry: WorldClockEntry) {
        // Prevent removing the last timezone
        guard timezones.count > 1 else { return }

        timezones.removeAll { $0.id == entry.id }

        // If we removed the primary, set a new primary
        if settings.primaryTimezoneId == entry.id {
            settings.primaryTimezoneId = timezones.first?.id
            saveSettings()
        }

        saveTimezones()
    }

    func moveTimezone(from source: IndexSet, to destination: Int) {
        timezones.move(fromOffsets: source, toOffset: destination)
        saveTimezones()
    }

    func setUse24HourFormat(_ use24Hour: Bool) {
        settings.use24HourFormat = use24Hour
        saveSettings()
    }

    func setShowSeconds(_ show: Bool) {
        settings.showSeconds = show
        saveSettings()
    }

    func setShowTimezoneOffset(_ show: Bool) {
        settings.showTimezoneOffset = show
        saveSettings()
    }

    func setDisplayMode(_ mode: DisplayMode) {
        settings.displayMode = mode
        saveSettings()
    }

    func setUseMonospacedFont(_ useMonospaced: Bool) {
        settings.useMonospacedFont = useMonospaced
        saveSettings()
    }

    func hourOffset(for entry: WorldClockEntry) -> String {
        timezoneService.hourOffset(for: entry)
    }

    @discardableResult
    func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        do {
            try launchAtLoginService.setEnabled(enabled)
            settings.launchAtLogin = enabled
            saveSettings()
            return true
        } catch {
            return false
        }
    }

    func searchTimezones(query: String) -> [TimezoneSearchResult] {
        timezoneService.searchTimezones(query: query)
    }

    private func saveTimezones() {
        preferencesService.saveTimezones(timezones)
    }

    private func saveSettings() {
        preferencesService.saveSettings(settings)
    }
}
