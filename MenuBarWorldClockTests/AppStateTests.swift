import XCTest
@testable import MenuBarWorldClock

// MARK: - Mock Services

final class MockPreferencesService: PreferencesServiceProtocol {
    var storedTimezones: [WorldClockEntry] = []
    var storedSettings: AppSettings = .default
    var loadTimezonesCalled = false
    var saveTimezonesCalled = false
    var loadSettingsCalled = false
    var saveSettingsCalled = false

    func loadTimezones() -> [WorldClockEntry] {
        loadTimezonesCalled = true
        return storedTimezones.isEmpty ? WorldClockEntry.defaultTimezones : storedTimezones
    }

    func saveTimezones(_ timezones: [WorldClockEntry]) {
        saveTimezonesCalled = true
        storedTimezones = timezones
    }

    func loadSettings() -> AppSettings {
        loadSettingsCalled = true
        return storedSettings
    }

    func saveSettings(_ settings: AppSettings) {
        saveSettingsCalled = true
        storedSettings = settings
    }
}

final class MockTimezoneService: TimezoneServiceProtocol {
    var formattedTimeResult = "12:00:00"
    var dayOffsetResult = 0
    var hourOffsetResult = "+0"
    var searchResults: [TimezoneSearchResult] = []

    func formattedTime(for entry: WorldClockEntry, use24Hour: Bool, showSeconds: Bool, date: Date) -> String {
        return formattedTimeResult
    }

    func dayOffset(for entry: WorldClockEntry, date: Date) -> Int {
        return dayOffsetResult
    }

    func hourOffset(for entry: WorldClockEntry) -> String {
        return hourOffsetResult
    }

    func searchTimezones(query: String) -> [TimezoneSearchResult] {
        return searchResults
    }
}

final class MockLaunchAtLoginService: LaunchAtLoginServiceProtocol {
    var isEnabled: Bool = false
    var setEnabledCalled = false
    var lastEnabledValue: Bool?

    func setEnabled(_ enabled: Bool) {
        setEnabledCalled = true
        lastEnabledValue = enabled
        isEnabled = enabled
    }
}

// MARK: - Tests

@MainActor
final class AppStateTests: XCTestCase {

    var mockPreferences: MockPreferencesService!
    var mockTimezone: MockTimezoneService!
    var mockLaunchAtLogin: MockLaunchAtLoginService!
    var sut: AppState!

    override func setUp() async throws {
        try await super.setUp()
        mockPreferences = MockPreferencesService()
        mockTimezone = MockTimezoneService()
        mockLaunchAtLogin = MockLaunchAtLoginService()
    }

    override func tearDown() async throws {
        sut = nil
        mockPreferences = nil
        mockTimezone = nil
        mockLaunchAtLogin = nil
        try await super.tearDown()
    }

    private func createAppState() -> AppState {
        return AppState(
            preferencesService: mockPreferences,
            timezoneService: mockTimezone,
            launchAtLoginService: mockLaunchAtLogin
        )
    }

    // MARK: - Initialization Tests

    func testInitializationLoadsData() {
        sut = createAppState()

        XCTAssertTrue(mockPreferences.loadTimezonesCalled)
        XCTAssertTrue(mockPreferences.loadSettingsCalled)
    }

    func testInitializationLoadsDefaultTimezones() {
        sut = createAppState()

        // The count may be less than defaultTimezones if current timezone matches a default
        // (deduplication removes duplicates), so check it's at least 1 and at most the default count
        XCTAssertGreaterThanOrEqual(sut.timezones.count, 1)
        XCTAssertLessThanOrEqual(sut.timezones.count, WorldClockEntry.defaultTimezones.count)

        // Verify no duplicates exist
        let identifiers = sut.timezones.map { $0.timezoneIdentifier }
        XCTAssertEqual(identifiers.count, Set(identifiers).count, "Should have no duplicate timezone identifiers")
    }

    // MARK: - Primary Timezone Tests

    func testPrimaryTimezoneReturnsFirstWhenNoPrimarySet() {
        sut = createAppState()

        XCTAssertEqual(sut.primaryTimezone?.id, sut.timezones.first?.id)
    }

    func testPrimaryTimezoneReturnsSetPrimary() {
        mockPreferences.storedTimezones = [
            WorldClockEntry(timezoneIdentifier: "Europe/London", cityName: "London", countryCode: "GB"),
            WorldClockEntry(timezoneIdentifier: "Asia/Tokyo", cityName: "Tokyo", countryCode: "JP")
        ]
        let tokyoId = mockPreferences.storedTimezones[1].id
        mockPreferences.storedSettings.primaryTimezoneId = tokyoId

        sut = createAppState()

        XCTAssertEqual(sut.primaryTimezone?.id, tokyoId)
        XCTAssertEqual(sut.primaryTimezone?.cityName, "Tokyo")
    }

    func testSetPrimaryTimezone() {
        sut = createAppState()
        let newPrimary = sut.timezones[2]

        sut.setPrimaryTimezone(newPrimary)

        XCTAssertEqual(sut.settings.primaryTimezoneId, newPrimary.id)
        XCTAssertTrue(mockPreferences.saveSettingsCalled)
    }

    func testIsPrimaryReturnsTrueForPrimary() {
        sut = createAppState()
        let primary = sut.timezones[0]

        XCTAssertTrue(sut.isPrimary(primary))
    }

    func testIsPrimaryReturnsFalseForNonPrimary() {
        sut = createAppState()
        let nonPrimary = sut.timezones[1]

        XCTAssertFalse(sut.isPrimary(nonPrimary))
    }

    // MARK: - Add/Remove Timezone Tests

    func testAddTimezone() {
        sut = createAppState()
        let initialCount = sut.timezones.count
        let newEntry = WorldClockEntry(
            timezoneIdentifier: "Europe/Paris",
            cityName: "Paris",
            countryCode: "FR"
        )

        sut.addTimezone(newEntry)

        XCTAssertEqual(sut.timezones.count, initialCount + 1)
        XCTAssertTrue(sut.timezones.contains(newEntry))
        XCTAssertTrue(mockPreferences.saveTimezonesCalled)
    }

    func testRemoveTimezone() {
        sut = createAppState()
        let initialCount = sut.timezones.count
        let toRemove = sut.timezones[1]

        sut.removeTimezone(toRemove)

        XCTAssertEqual(sut.timezones.count, initialCount - 1)
        XCTAssertFalse(sut.timezones.contains(toRemove))
        XCTAssertTrue(mockPreferences.saveTimezonesCalled)
    }

    func testCannotRemoveLastTimezone() {
        mockPreferences.storedTimezones = [
            WorldClockEntry(timezoneIdentifier: "Europe/London", cityName: "London", countryCode: "GB")
        ]
        sut = createAppState()

        sut.removeTimezone(sut.timezones[0])

        XCTAssertEqual(sut.timezones.count, 1)
    }

    func testRemovePrimaryTimezoneSetNewPrimary() {
        mockPreferences.storedTimezones = [
            WorldClockEntry(timezoneIdentifier: "Europe/London", cityName: "London", countryCode: "GB"),
            WorldClockEntry(timezoneIdentifier: "Asia/Tokyo", cityName: "Tokyo", countryCode: "JP")
        ]
        mockPreferences.storedSettings.primaryTimezoneId = mockPreferences.storedTimezones[0].id
        sut = createAppState()

        let primaryToRemove = sut.timezones[0]
        sut.removeTimezone(primaryToRemove)

        XCTAssertNotNil(sut.settings.primaryTimezoneId)
        XCTAssertNotEqual(sut.settings.primaryTimezoneId, primaryToRemove.id)
    }

    // MARK: - Move Timezone Tests

    func testMoveTimezone() {
        sut = createAppState()
        let originalFirst = sut.timezones[0]
        let originalSecond = sut.timezones[1]

        sut.moveTimezone(from: IndexSet(integer: 0), to: 2)

        XCTAssertEqual(sut.timezones[0].id, originalSecond.id)
        XCTAssertEqual(sut.timezones[1].id, originalFirst.id)
        XCTAssertTrue(mockPreferences.saveTimezonesCalled)
    }

    // MARK: - Settings Tests

    func testSetUse24HourFormat() {
        sut = createAppState()

        sut.setUse24HourFormat(false)

        XCTAssertFalse(sut.settings.use24HourFormat)
        XCTAssertTrue(mockPreferences.saveSettingsCalled)
    }

    func testSetShowSeconds() {
        sut = createAppState()

        sut.setShowSeconds(false)

        XCTAssertFalse(sut.settings.showSeconds)
        XCTAssertTrue(mockPreferences.saveSettingsCalled)
    }

    func testSetShowTimezoneOffset() {
        sut = createAppState()

        sut.setShowTimezoneOffset(true)

        XCTAssertTrue(sut.settings.showTimezoneOffset)
        XCTAssertTrue(mockPreferences.saveSettingsCalled)
    }

    func testSetDisplayMode() {
        sut = createAppState()

        sut.setDisplayMode(.flagOnly)
        XCTAssertEqual(sut.settings.displayMode, .flagOnly)

        sut.setDisplayMode(.locationOnly)
        XCTAssertEqual(sut.settings.displayMode, .locationOnly)

        sut.setDisplayMode(.both)
        XCTAssertEqual(sut.settings.displayMode, .both)

        XCTAssertTrue(mockPreferences.saveSettingsCalled)
    }

    func testSetLaunchAtLogin() {
        sut = createAppState()

        sut.setLaunchAtLogin(true)

        XCTAssertTrue(sut.settings.launchAtLogin)
        XCTAssertTrue(mockLaunchAtLogin.setEnabledCalled)
        XCTAssertEqual(mockLaunchAtLogin.lastEnabledValue, true)
        XCTAssertTrue(mockPreferences.saveSettingsCalled)
    }

    // MARK: - Time Formatting Tests

    func testFormattedTime() {
        mockTimezone.formattedTimeResult = "14:30:00"
        sut = createAppState()
        let entry = sut.timezones[0]

        let result = sut.formattedTime(for: entry)

        XCTAssertEqual(result, "14:30:00")
    }

    func testDayOffsetStringPositive() {
        mockTimezone.dayOffsetResult = 1
        sut = createAppState()
        let entry = sut.timezones[0]

        let result = sut.dayOffsetString(for: entry)

        XCTAssertEqual(result, "+1 day")
    }

    func testDayOffsetStringNegative() {
        mockTimezone.dayOffsetResult = -1
        sut = createAppState()
        let entry = sut.timezones[0]

        let result = sut.dayOffsetString(for: entry)

        XCTAssertEqual(result, "-1 day")
    }

    func testDayOffsetStringZero() {
        mockTimezone.dayOffsetResult = 0
        sut = createAppState()
        let entry = sut.timezones[0]

        let result = sut.dayOffsetString(for: entry)

        XCTAssertNil(result)
    }

    // MARK: - Search Tests

    func testSearchTimezones() {
        mockTimezone.searchResults = [
            TimezoneSearchResult(
                timezoneIdentifier: "Europe/Paris",
                cityName: "Paris",
                countryCode: "FR",
                countryName: "France"
            )
        ]
        sut = createAppState()

        let results = sut.searchTimezones(query: "Paris")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.cityName, "Paris")
    }

    // MARK: - Invalid Primary Timezone Recovery Tests

    func testInvalidPrimaryTimezoneIsReset() {
        mockPreferences.storedTimezones = [
            WorldClockEntry(timezoneIdentifier: "Europe/London", cityName: "London", countryCode: "GB")
        ]
        mockPreferences.storedSettings.primaryTimezoneId = UUID() // Non-existent ID

        sut = createAppState()

        // Should reset to first timezone
        XCTAssertEqual(sut.settings.primaryTimezoneId, sut.timezones.first?.id)
    }

    // MARK: - Hour Offset Tests

    func testHourOffset() {
        mockTimezone.hourOffsetResult = "+5"
        sut = createAppState()
        let entry = sut.timezones[0]

        let result = sut.hourOffset(for: entry)

        XCTAssertEqual(result, "+5")
    }

    // MARK: - Deduplication Tests

    func testDeduplicationRemovesDuplicates() {
        // Create timezones with duplicate identifiers
        mockPreferences.storedTimezones = [
            WorldClockEntry(timezoneIdentifier: "Europe/London", cityName: "London", countryCode: "GB"),
            WorldClockEntry(timezoneIdentifier: "Asia/Tokyo", cityName: "Tokyo", countryCode: "JP"),
            WorldClockEntry(timezoneIdentifier: "Europe/London", cityName: "London Dup", countryCode: "GB") // Duplicate
        ]

        sut = createAppState()

        XCTAssertEqual(sut.timezones.count, 2)
        XCTAssertTrue(mockPreferences.saveTimezonesCalled, "Should save after deduplication")

        // Verify the first occurrence was kept
        XCTAssertEqual(sut.timezones[0].cityName, "London")
        XCTAssertEqual(sut.timezones[1].cityName, "Tokyo")
    }

    func testDeduplicationPreservesOrderOfFirstOccurrence() {
        mockPreferences.storedTimezones = [
            WorldClockEntry(timezoneIdentifier: "America/New_York", cityName: "New York", countryCode: "US"),
            WorldClockEntry(timezoneIdentifier: "Europe/London", cityName: "London", countryCode: "GB"),
            WorldClockEntry(timezoneIdentifier: "America/New_York", cityName: "NYC", countryCode: "US") // Duplicate
        ]

        sut = createAppState()

        XCTAssertEqual(sut.timezones.count, 2)
        XCTAssertEqual(sut.timezones[0].timezoneIdentifier, "America/New_York")
        XCTAssertEqual(sut.timezones[0].cityName, "New York") // First occurrence kept
        XCTAssertEqual(sut.timezones[1].timezoneIdentifier, "Europe/London")
    }
}
