import XCTest
@testable import MenuBarWorldClock

final class TimezoneServiceTests: XCTestCase {

    var sut: TimezoneService!

    override func setUp() {
        super.setUp()
        sut = TimezoneService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Time Formatting Tests

    func testFormattedTime24Hour() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "UTC",
            cityName: "UTC",
            countryCode: "UN"
        )

        // Create a fixed date: 2024-01-15 14:30:45 UTC
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        let result = sut.formattedTime(for: entry, use24Hour: true, showSeconds: true, date: date)

        XCTAssertEqual(result, "14:30:45")
    }

    func testFormattedTime24HourNoSeconds() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "UTC",
            cityName: "UTC",
            countryCode: "UN"
        )

        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        let result = sut.formattedTime(for: entry, use24Hour: true, showSeconds: false, date: date)

        XCTAssertEqual(result, "14:30")
    }

    func testFormattedTime12Hour() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "UTC",
            cityName: "UTC",
            countryCode: "UN"
        )

        // Create a fixed date: 2024-01-15 14:30:45 UTC
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        let result = sut.formattedTime(for: entry, use24Hour: false, showSeconds: true, date: date)

        // Check that 12-hour format is used (hour should be 2, not 14)
        XCTAssertTrue(result.contains("2:30:45"), "Expected 12-hour format time, got: \(result)")
        // Check for AM/PM indicator (locale-independent - could be PM, pm, p.m., etc.)
        let hasAmPmIndicator = result.lowercased().contains("pm") || result.lowercased().contains("p.m")
        XCTAssertTrue(hasAmPmIndicator, "Expected PM indicator, got: \(result)")
    }

    func testFormattedTime12HourNoSeconds() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "UTC",
            cityName: "UTC",
            countryCode: "UN"
        )

        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        let result = sut.formattedTime(for: entry, use24Hour: false, showSeconds: false, date: date)

        // Check that 12-hour format without seconds
        XCTAssertTrue(result.contains("2:30"), "Expected 12-hour format time, got: \(result)")
        XCTAssertFalse(result.contains("45"), "Should not contain seconds, got: \(result)")
    }

    func testFormattedTimeInvalidTimezone() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "Invalid/Timezone",
            cityName: "Invalid",
            countryCode: "XX"
        )

        let result = sut.formattedTime(for: entry, use24Hour: true, date: Date())

        XCTAssertEqual(result, "--:--")
    }

    // MARK: - Day Offset Tests

    func testDayOffsetSameDay() {
        // Use a timezone close to local to ensure same day
        let entry = WorldClockEntry(
            timezoneIdentifier: TimeZone.current.identifier,
            cityName: "Local",
            countryCode: "US"
        )

        let result = sut.dayOffset(for: entry, date: Date())

        XCTAssertEqual(result, 0)
    }

    func testDayOffsetAhead() {
        // Test with a timezone that's ahead
        // At midnight UTC, Tokyo (UTC+9) is already the next day
        let tokyoEntry = WorldClockEntry(
            timezoneIdentifier: "Asia/Tokyo",
            cityName: "Tokyo",
            countryCode: "JP"
        )

        // Create a date at 20:00 UTC - it will be 05:00 next day in Tokyo
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 20
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        // Use a custom calendar with UTC timezone for this test
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        let service = TimezoneService(calendar: utcCalendar)
        let result = service.dayOffset(for: tokyoEntry, date: date)

        XCTAssertEqual(result, 1)
    }

    func testDayOffsetInvalidTimezone() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "Invalid/Timezone",
            cityName: "Invalid",
            countryCode: "XX"
        )

        let result = sut.dayOffset(for: entry, date: Date())

        XCTAssertEqual(result, 0)
    }

    // MARK: - Search Tests

    func testSearchTimezonesByCityName() {
        let results = sut.searchTimezones(query: "london")

        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.cityName == "London" })
    }

    func testSearchTimezonesByCountryName() {
        let results = sut.searchTimezones(query: "japan")

        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.cityName == "Tokyo" })
    }

    func testSearchTimezonesEmptyQuery() {
        let results = sut.searchTimezones(query: "")

        XCTAssertTrue(results.isEmpty)
    }

    func testSearchTimezonesNoResults() {
        let results = sut.searchTimezones(query: "xyznonexistent")

        XCTAssertTrue(results.isEmpty)
    }

    func testSearchTimezonesCaseInsensitive() {
        let lowerResults = sut.searchTimezones(query: "new york")
        let upperResults = sut.searchTimezones(query: "NEW YORK")
        let mixedResults = sut.searchTimezones(query: "New York")

        XCTAssertFalse(lowerResults.isEmpty)
        XCTAssertEqual(lowerResults.count, upperResults.count)
        XCTAssertEqual(lowerResults.count, mixedResults.count)
    }

    func testSearchResultsAreSorted() {
        let results = sut.searchTimezones(query: "a")

        guard results.count > 1 else { return }

        for i in 0..<(results.count - 1) {
            XCTAssertLessThanOrEqual(results[i].cityName, results[i + 1].cityName)
        }
    }

    func testSearchResultToWorldClockEntry() {
        let results = sut.searchTimezones(query: "tokyo")

        guard let tokyoResult = results.first(where: { $0.cityName == "Tokyo" }) else {
            XCTFail("Tokyo not found in results")
            return
        }

        let entry = tokyoResult.toWorldClockEntry()

        XCTAssertEqual(entry.timezoneIdentifier, tokyoResult.timezoneIdentifier)
        XCTAssertEqual(entry.cityName, tokyoResult.cityName)
        XCTAssertEqual(entry.countryCode, tokyoResult.countryCode)
    }

    func testSearchResultFlagEmoji() {
        let results = sut.searchTimezones(query: "tokyo")

        guard let tokyoResult = results.first(where: { $0.cityName == "Tokyo" }) else {
            XCTFail("Tokyo not found in results")
            return
        }

        XCTAssertEqual(tokyoResult.flagEmoji, "🇯🇵")
    }

    // MARK: - Known Timezone Mapping Tests

    func testKnownTimezoneMappings() {
        // Test that well-known cities are properly mapped
        let newYorkResults = sut.searchTimezones(query: "New York")
        XCTAssertTrue(newYorkResults.contains { $0.timezoneIdentifier == "America/New_York" })

        let londonResults = sut.searchTimezones(query: "London")
        XCTAssertTrue(londonResults.contains { $0.timezoneIdentifier == "Europe/London" })

        let tokyoResults = sut.searchTimezones(query: "Tokyo")
        XCTAssertTrue(tokyoResults.contains { $0.timezoneIdentifier == "Asia/Tokyo" })

        let sydneyResults = sut.searchTimezones(query: "Sydney")
        XCTAssertTrue(sydneyResults.contains { $0.timezoneIdentifier == "Australia/Sydney" })
    }

    // MARK: - Hour Offset Tests

    func testHourOffsetPositive() {
        // Tokyo is UTC+9
        let entry = WorldClockEntry(
            timezoneIdentifier: "Asia/Tokyo",
            cityName: "Tokyo",
            countryCode: "JP"
        )

        // Use UTC calendar for consistent testing
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let service = TimezoneService(calendar: utcCalendar)

        let result = service.hourOffset(for: entry)

        XCTAssertEqual(result, "+9")
    }

    func testHourOffsetNegative() {
        // New York is UTC-5 (standard time) or UTC-4 (daylight saving)
        let entry = WorldClockEntry(
            timezoneIdentifier: "America/New_York",
            cityName: "New York",
            countryCode: "US"
        )

        // Use UTC calendar for consistent testing
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let service = TimezoneService(calendar: utcCalendar)

        let result = service.hourOffset(for: entry)

        // Should be negative (either -5 or -4 depending on DST)
        XCTAssertTrue(result.hasPrefix("-"), "New York offset should be negative, got: \(result)")
    }

    func testHourOffsetZero() {
        // UTC should have zero offset from UTC
        let entry = WorldClockEntry(
            timezoneIdentifier: "UTC",
            cityName: "UTC",
            countryCode: "UN"
        )

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let service = TimezoneService(calendar: utcCalendar)

        let result = service.hourOffset(for: entry)

        XCTAssertEqual(result, "0")
    }

    func testHourOffsetHalfHour() {
        // India is UTC+5:30
        let entry = WorldClockEntry(
            timezoneIdentifier: "Asia/Kolkata",
            cityName: "Mumbai",
            countryCode: "IN"
        )

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let service = TimezoneService(calendar: utcCalendar)

        let result = service.hourOffset(for: entry)

        XCTAssertEqual(result, "+5.5")
    }

    func testHourOffsetInvalidTimezone() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "Invalid/Timezone",
            cityName: "Invalid",
            countryCode: "XX"
        )

        let result = sut.hourOffset(for: entry)

        XCTAssertEqual(result, "")
    }
}
