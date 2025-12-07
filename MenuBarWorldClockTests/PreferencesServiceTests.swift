import XCTest
@testable import MenuBarWorldClock

final class PreferencesServiceTests: XCTestCase {

    var sut: PreferencesService!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.12nines.worldclock.tests")!
        testDefaults.removePersistentDomain(forName: "com.12nines.worldclock.tests")
        sut = PreferencesService(userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.12nines.worldclock.tests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Timezone Persistence Tests

    func testLoadTimezonesReturnsDefaultsWhenEmpty() {
        let timezones = sut.loadTimezones()

        XCTAssertEqual(timezones.count, WorldClockEntry.defaultTimezones.count)
    }

    func testSaveAndLoadTimezones() {
        let customTimezones = [
            WorldClockEntry(
                timezoneIdentifier: "Europe/Paris",
                cityName: "Paris",
                countryCode: "FR"
            ),
            WorldClockEntry(
                timezoneIdentifier: "Asia/Tokyo",
                cityName: "Tokyo",
                countryCode: "JP"
            )
        ]

        sut.saveTimezones(customTimezones)
        let loadedTimezones = sut.loadTimezones()

        XCTAssertEqual(loadedTimezones.count, 2)
        XCTAssertEqual(loadedTimezones[0].cityName, "Paris")
        XCTAssertEqual(loadedTimezones[1].cityName, "Tokyo")
    }

    func testSaveEmptyTimezones() {
        // First save some timezones
        let timezones = [
            WorldClockEntry(
                timezoneIdentifier: "Europe/London",
                cityName: "London",
                countryCode: "GB"
            )
        ]
        sut.saveTimezones(timezones)

        // Then save empty array
        sut.saveTimezones([])
        let loaded = sut.loadTimezones()

        XCTAssertTrue(loaded.isEmpty)
    }

    func testTimezoneOrderIsPreserved() {
        let timezones = [
            WorldClockEntry(timezoneIdentifier: "America/New_York", cityName: "New York", countryCode: "US"),
            WorldClockEntry(timezoneIdentifier: "Europe/London", cityName: "London", countryCode: "GB"),
            WorldClockEntry(timezoneIdentifier: "Asia/Tokyo", cityName: "Tokyo", countryCode: "JP"),
        ]

        sut.saveTimezones(timezones)
        let loaded = sut.loadTimezones()

        XCTAssertEqual(loaded[0].cityName, "New York")
        XCTAssertEqual(loaded[1].cityName, "London")
        XCTAssertEqual(loaded[2].cityName, "Tokyo")
    }

    func testTimezoneIdsArePreserved() {
        let id = UUID()
        let timezones = [
            WorldClockEntry(id: id, timezoneIdentifier: "Europe/Paris", cityName: "Paris", countryCode: "FR")
        ]

        sut.saveTimezones(timezones)
        let loaded = sut.loadTimezones()

        XCTAssertEqual(loaded.first?.id, id)
    }

    // MARK: - Settings Persistence Tests

    func testLoadSettingsReturnsDefaultsWhenEmpty() {
        let settings = sut.loadSettings()

        XCTAssertEqual(settings, AppSettings.default)
    }

    func testSaveAndLoadSettings() {
        let customSettings = AppSettings(
            use24HourFormat: false,
            launchAtLogin: true,
            primaryTimezoneId: UUID()
        )

        sut.saveSettings(customSettings)
        let loaded = sut.loadSettings()

        XCTAssertEqual(loaded.use24HourFormat, false)
        XCTAssertEqual(loaded.launchAtLogin, true)
        XCTAssertEqual(loaded.primaryTimezoneId, customSettings.primaryTimezoneId)
    }

    func testSaveSettingsPreserves24HourFormat() {
        var settings = AppSettings.default
        settings.use24HourFormat = false

        sut.saveSettings(settings)
        let loaded = sut.loadSettings()

        XCTAssertFalse(loaded.use24HourFormat)
    }

    func testSaveSettingsPreservesLaunchAtLogin() {
        var settings = AppSettings.default
        settings.launchAtLogin = true

        sut.saveSettings(settings)
        let loaded = sut.loadSettings()

        XCTAssertTrue(loaded.launchAtLogin)
    }

    func testSaveSettingsPreservesPrimaryTimezoneId() {
        let primaryId = UUID()
        var settings = AppSettings.default
        settings.primaryTimezoneId = primaryId

        sut.saveSettings(settings)
        let loaded = sut.loadSettings()

        XCTAssertEqual(loaded.primaryTimezoneId, primaryId)
    }

    func testSettingsWithNilPrimaryTimezoneId() {
        var settings = AppSettings.default
        settings.primaryTimezoneId = nil

        sut.saveSettings(settings)
        let loaded = sut.loadSettings()

        XCTAssertNil(loaded.primaryTimezoneId)
    }

    func testSaveSettingsPreservesShowSeconds() {
        var settings = AppSettings.default
        settings.showSeconds = false

        sut.saveSettings(settings)
        let loaded = sut.loadSettings()

        XCTAssertFalse(loaded.showSeconds)
    }

    func testSaveSettingsPreservesShowTimezoneOffset() {
        var settings = AppSettings.default
        settings.showTimezoneOffset = true

        sut.saveSettings(settings)
        let loaded = sut.loadSettings()

        XCTAssertTrue(loaded.showTimezoneOffset)
    }

    func testSaveSettingsPreservesDisplayMode() {
        var settings = AppSettings.default
        settings.displayMode = .flagOnly

        sut.saveSettings(settings)
        let loaded = sut.loadSettings()

        XCTAssertEqual(loaded.displayMode, .flagOnly)

        // Test other modes
        settings.displayMode = .locationOnly
        sut.saveSettings(settings)
        XCTAssertEqual(sut.loadSettings().displayMode, .locationOnly)

        settings.displayMode = .both
        sut.saveSettings(settings)
        XCTAssertEqual(sut.loadSettings().displayMode, .both)
    }

    // MARK: - Independence Tests

    func testTimezonesAndSettingsAreIndependent() {
        // Save timezones
        let timezones = [
            WorldClockEntry(timezoneIdentifier: "Europe/Paris", cityName: "Paris", countryCode: "FR")
        ]
        sut.saveTimezones(timezones)

        // Save settings
        let settings = AppSettings(use24HourFormat: false, launchAtLogin: true, primaryTimezoneId: nil)
        sut.saveSettings(settings)

        // Verify both are independent
        let loadedTimezones = sut.loadTimezones()
        let loadedSettings = sut.loadSettings()

        XCTAssertEqual(loadedTimezones.count, 1)
        XCTAssertEqual(loadedTimezones.first?.cityName, "Paris")
        XCTAssertFalse(loadedSettings.use24HourFormat)
        XCTAssertTrue(loadedSettings.launchAtLogin)
    }
}
