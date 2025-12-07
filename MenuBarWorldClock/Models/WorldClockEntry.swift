import Foundation

struct WorldClockEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let timezoneIdentifier: String
    let cityName: String
    let countryCode: String

    var timezone: TimeZone? {
        TimeZone(identifier: timezoneIdentifier)
    }

    var flagEmoji: String {
        countryCodeToFlag(countryCode)
    }

    init(id: UUID = UUID(), timezoneIdentifier: String, cityName: String, countryCode: String) {
        self.id = id
        self.timezoneIdentifier = timezoneIdentifier
        self.cityName = cityName
        self.countryCode = countryCode
    }

    private func countryCodeToFlag(_ code: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in code.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag
    }
}

extension WorldClockEntry {
    static let defaultTimezones: [WorldClockEntry] = [
        WorldClockEntry(
            timezoneIdentifier: TimeZone.current.identifier,
            cityName: cityNameFromIdentifier(TimeZone.current.identifier),
            countryCode: countryCodeFromIdentifier(TimeZone.current.identifier)
        ),
        WorldClockEntry(
            timezoneIdentifier: "Asia/Hong_Kong",
            cityName: "Hong Kong",
            countryCode: "HK"
        ),
        WorldClockEntry(
            timezoneIdentifier: "Asia/Kolkata",
            cityName: "Mumbai",
            countryCode: "IN"
        ),
        WorldClockEntry(
            timezoneIdentifier: "Europe/London",
            cityName: "London",
            countryCode: "GB"
        ),
        WorldClockEntry(
            timezoneIdentifier: "America/New_York",
            cityName: "New York",
            countryCode: "US"
        )
    ]

    private static func cityNameFromIdentifier(_ identifier: String) -> String {
        let components = identifier.split(separator: "/")
        if let city = components.last {
            return String(city).replacingOccurrences(of: "_", with: " ")
        }
        return identifier
    }

    private static func countryCodeFromIdentifier(_ identifier: String) -> String {
        // Map common timezone regions to country codes
        let regionMappings: [String: String] = [
            "America": "US",
            "Europe": "GB",
            "Asia": "CN",
            "Australia": "AU",
            "Africa": "ZA",
            "Pacific": "NZ"
        ]

        let components = identifier.split(separator: "/")
        if let region = components.first {
            return regionMappings[String(region)] ?? "UN"
        }
        return "UN"
    }
}
