import XCTest
@testable import MenuBarWorldClock

final class WorldClockEntryTests: XCTestCase {

    func testInitialization() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "America/New_York",
            cityName: "New York",
            countryCode: "US"
        )

        XCTAssertEqual(entry.timezoneIdentifier, "America/New_York")
        XCTAssertEqual(entry.cityName, "New York")
        XCTAssertEqual(entry.countryCode, "US")
        XCTAssertNotNil(entry.id)
    }

    func testTimezoneProperty() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "Europe/London",
            cityName: "London",
            countryCode: "GB"
        )

        XCTAssertNotNil(entry.timezone)
        XCTAssertEqual(entry.timezone?.identifier, "Europe/London")
    }

    func testInvalidTimezone() {
        let entry = WorldClockEntry(
            timezoneIdentifier: "Invalid/Timezone",
            cityName: "Invalid",
            countryCode: "XX"
        )

        XCTAssertNil(entry.timezone)
    }

    func testFlagEmoji() {
        let usEntry = WorldClockEntry(
            timezoneIdentifier: "America/New_York",
            cityName: "New York",
            countryCode: "US"
        )
        XCTAssertEqual(usEntry.flagEmoji, "🇺🇸")

        let gbEntry = WorldClockEntry(
            timezoneIdentifier: "Europe/London",
            cityName: "London",
            countryCode: "GB"
        )
        XCTAssertEqual(gbEntry.flagEmoji, "🇬🇧")

        let jpEntry = WorldClockEntry(
            timezoneIdentifier: "Asia/Tokyo",
            cityName: "Tokyo",
            countryCode: "JP"
        )
        XCTAssertEqual(jpEntry.flagEmoji, "🇯🇵")

        let hkEntry = WorldClockEntry(
            timezoneIdentifier: "Asia/Hong_Kong",
            cityName: "Hong Kong",
            countryCode: "HK"
        )
        XCTAssertEqual(hkEntry.flagEmoji, "🇭🇰")

        let inEntry = WorldClockEntry(
            timezoneIdentifier: "Asia/Kolkata",
            cityName: "Mumbai",
            countryCode: "IN"
        )
        XCTAssertEqual(inEntry.flagEmoji, "🇮🇳")
    }

    func testEquatable() {
        let id = UUID()
        let entry1 = WorldClockEntry(
            id: id,
            timezoneIdentifier: "America/New_York",
            cityName: "New York",
            countryCode: "US"
        )
        let entry2 = WorldClockEntry(
            id: id,
            timezoneIdentifier: "America/New_York",
            cityName: "New York",
            countryCode: "US"
        )

        XCTAssertEqual(entry1, entry2)
    }

    func testCodable() throws {
        let entry = WorldClockEntry(
            timezoneIdentifier: "Asia/Tokyo",
            cityName: "Tokyo",
            countryCode: "JP"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        let decodedEntry = try decoder.decode(WorldClockEntry.self, from: data)

        XCTAssertEqual(entry.id, decodedEntry.id)
        XCTAssertEqual(entry.timezoneIdentifier, decodedEntry.timezoneIdentifier)
        XCTAssertEqual(entry.cityName, decodedEntry.cityName)
        XCTAssertEqual(entry.countryCode, decodedEntry.countryCode)
    }

    func testDefaultTimezones() {
        let defaults = WorldClockEntry.defaultTimezones

        XCTAssertEqual(defaults.count, 5)

        // Verify expected cities are present (excluding local timezone which varies)
        let cityNames = defaults.map { $0.cityName }
        XCTAssertTrue(cityNames.contains("Hong Kong"))
        XCTAssertTrue(cityNames.contains("Mumbai"))
        XCTAssertTrue(cityNames.contains("London"))
        XCTAssertTrue(cityNames.contains("New York"))
    }

    func testHashable() {
        let entry1 = WorldClockEntry(
            timezoneIdentifier: "America/New_York",
            cityName: "New York",
            countryCode: "US"
        )
        let entry2 = WorldClockEntry(
            timezoneIdentifier: "Europe/London",
            cityName: "London",
            countryCode: "GB"
        )

        var set = Set<WorldClockEntry>()
        set.insert(entry1)
        set.insert(entry2)

        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(entry1))
        XCTAssertTrue(set.contains(entry2))
    }
}
