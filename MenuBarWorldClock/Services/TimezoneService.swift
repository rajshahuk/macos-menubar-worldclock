import Foundation

protocol TimezoneServiceProtocol {
    func formattedTime(for entry: WorldClockEntry, use24Hour: Bool, showSeconds: Bool, date: Date) -> String
    func dayOffset(for entry: WorldClockEntry, date: Date) -> Int
    func hourOffset(for entry: WorldClockEntry) -> String
    func searchTimezones(query: String) -> [TimezoneSearchResult]
}

struct TimezoneSearchResult: Identifiable, Equatable {
    let id = UUID()
    let timezoneIdentifier: String
    let cityName: String
    let countryCode: String
    let countryName: String

    var flagEmoji: String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag
    }

    func toWorldClockEntry() -> WorldClockEntry {
        WorldClockEntry(
            timezoneIdentifier: timezoneIdentifier,
            cityName: cityName,
            countryCode: countryCode
        )
    }
}

final class TimezoneService: TimezoneServiceProtocol {
    private let calendar: Calendar
    private let timezoneMappings: [String: (city: String, country: String, countryCode: String)]

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.timezoneMappings = Self.buildTimezoneMappings()
    }

    func formattedTime(for entry: WorldClockEntry, use24Hour: Bool, showSeconds: Bool = true, date: Date = Date()) -> String {
        guard let timezone = entry.timezone else { return "--:--" }

        let formatter = DateFormatter()
        formatter.timeZone = timezone

        if use24Hour {
            formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.dateFormat = showSeconds ? "h:mm:ss a" : "h:mm a"
        }

        return formatter.string(from: date)
    }

    func dayOffset(for entry: WorldClockEntry, date: Date = Date()) -> Int {
        guard let timezone = entry.timezone else { return 0 }

        var localCalendar = calendar
        localCalendar.timeZone = TimeZone.current

        var targetCalendar = calendar
        targetCalendar.timeZone = timezone

        let localDay = localCalendar.component(.day, from: date)
        let targetDay = targetCalendar.component(.day, from: date)

        let localMonth = localCalendar.component(.month, from: date)
        let targetMonth = targetCalendar.component(.month, from: date)

        if localMonth == targetMonth {
            return targetDay - localDay
        } else if targetMonth > localMonth || (localMonth == 12 && targetMonth == 1) {
            return 1
        } else {
            return -1
        }
    }

    func hourOffset(for entry: WorldClockEntry) -> String {
        guard let timezone = entry.timezone else { return "" }

        let localOffset = TimeZone.current.secondsFromGMT()
        let targetOffset = timezone.secondsFromGMT()
        let differenceInSeconds = targetOffset - localOffset
        let differenceInHours = Double(differenceInSeconds) / 3600.0

        if differenceInHours == 0 {
            return "0"
        } else if differenceInHours > 0 {
            if differenceInHours == differenceInHours.rounded() {
                return "+\(Int(differenceInHours))"
            } else {
                return "+\(String(format: "%.1f", differenceInHours))"
            }
        } else {
            if differenceInHours == differenceInHours.rounded() {
                return "\(Int(differenceInHours))"
            } else {
                return "\(String(format: "%.1f", differenceInHours))"
            }
        }
    }

    func searchTimezones(query: String) -> [TimezoneSearchResult] {
        guard !query.isEmpty else { return [] }

        let lowercasedQuery = query.lowercased()

        return timezoneMappings.compactMap { identifier, info in
            let matchesCity = info.city.lowercased().contains(lowercasedQuery)
            let matchesCountry = info.country.lowercased().contains(lowercasedQuery)
            let matchesIdentifier = identifier.lowercased().contains(lowercasedQuery)

            if matchesCity || matchesCountry || matchesIdentifier {
                return TimezoneSearchResult(
                    timezoneIdentifier: identifier,
                    cityName: info.city,
                    countryCode: info.countryCode,
                    countryName: info.country
                )
            }
            return nil
        }
        .sorted { $0.cityName < $1.cityName }
    }

    private static func buildTimezoneMappings() -> [String: (city: String, country: String, countryCode: String)] {
        var mappings: [String: (city: String, country: String, countryCode: String)] = [:]

        // Manual mappings for common timezones with better names
        let knownMappings: [String: (city: String, country: String, countryCode: String)] = [
            "America/New_York": ("New York", "United States", "US"),
            "America/Los_Angeles": ("Los Angeles", "United States", "US"),
            "America/Chicago": ("Chicago", "United States", "US"),
            "America/Denver": ("Denver", "United States", "US"),
            "America/Phoenix": ("Phoenix", "United States", "US"),
            "America/Toronto": ("Toronto", "Canada", "CA"),
            "America/Vancouver": ("Vancouver", "Canada", "CA"),
            "America/Mexico_City": ("Mexico City", "Mexico", "MX"),
            "America/Sao_Paulo": ("São Paulo", "Brazil", "BR"),
            "America/Buenos_Aires": ("Buenos Aires", "Argentina", "AR"),
            "America/Lima": ("Lima", "Peru", "PE"),
            "America/Bogota": ("Bogotá", "Colombia", "CO"),
            "Europe/London": ("London", "United Kingdom", "GB"),
            "Europe/Paris": ("Paris", "France", "FR"),
            "Europe/Berlin": ("Berlin", "Germany", "DE"),
            "Europe/Rome": ("Rome", "Italy", "IT"),
            "Europe/Madrid": ("Madrid", "Spain", "ES"),
            "Europe/Amsterdam": ("Amsterdam", "Netherlands", "NL"),
            "Europe/Brussels": ("Brussels", "Belgium", "BE"),
            "Europe/Vienna": ("Vienna", "Austria", "AT"),
            "Europe/Zurich": ("Zurich", "Switzerland", "CH"),
            "Europe/Stockholm": ("Stockholm", "Sweden", "SE"),
            "Europe/Oslo": ("Oslo", "Norway", "NO"),
            "Europe/Copenhagen": ("Copenhagen", "Denmark", "DK"),
            "Europe/Helsinki": ("Helsinki", "Finland", "FI"),
            "Europe/Warsaw": ("Warsaw", "Poland", "PL"),
            "Europe/Prague": ("Prague", "Czech Republic", "CZ"),
            "Europe/Budapest": ("Budapest", "Hungary", "HU"),
            "Europe/Athens": ("Athens", "Greece", "GR"),
            "Europe/Istanbul": ("Istanbul", "Turkey", "TR"),
            "Europe/Moscow": ("Moscow", "Russia", "RU"),
            "Europe/Dublin": ("Dublin", "Ireland", "IE"),
            "Europe/Lisbon": ("Lisbon", "Portugal", "PT"),
            "Asia/Tokyo": ("Tokyo", "Japan", "JP"),
            "Asia/Shanghai": ("Shanghai", "China", "CN"),
            "Asia/Hong_Kong": ("Hong Kong", "Hong Kong", "HK"),
            "Asia/Singapore": ("Singapore", "Singapore", "SG"),
            "Asia/Seoul": ("Seoul", "South Korea", "KR"),
            "Asia/Taipei": ("Taipei", "Taiwan", "TW"),
            "Asia/Bangkok": ("Bangkok", "Thailand", "TH"),
            "Asia/Jakarta": ("Jakarta", "Indonesia", "ID"),
            "Asia/Manila": ("Manila", "Philippines", "PH"),
            "Asia/Kuala_Lumpur": ("Kuala Lumpur", "Malaysia", "MY"),
            "Asia/Ho_Chi_Minh": ("Ho Chi Minh City", "Vietnam", "VN"),
            "Asia/Kolkata": ("Mumbai", "India", "IN"),
            "Asia/Dubai": ("Dubai", "United Arab Emirates", "AE"),
            "Asia/Riyadh": ("Riyadh", "Saudi Arabia", "SA"),
            "Asia/Tel_Aviv": ("Tel Aviv", "Israel", "IL"),
            "Asia/Karachi": ("Karachi", "Pakistan", "PK"),
            "Asia/Dhaka": ("Dhaka", "Bangladesh", "BD"),
            "Australia/Sydney": ("Sydney", "Australia", "AU"),
            "Australia/Melbourne": ("Melbourne", "Australia", "AU"),
            "Australia/Brisbane": ("Brisbane", "Australia", "AU"),
            "Australia/Perth": ("Perth", "Australia", "AU"),
            "Pacific/Auckland": ("Auckland", "New Zealand", "NZ"),
            "Pacific/Honolulu": ("Honolulu", "United States", "US"),
            "Pacific/Fiji": ("Fiji", "Fiji", "FJ"),
            "Africa/Cairo": ("Cairo", "Egypt", "EG"),
            "Africa/Johannesburg": ("Johannesburg", "South Africa", "ZA"),
            "Africa/Lagos": ("Lagos", "Nigeria", "NG"),
            "Africa/Nairobi": ("Nairobi", "Kenya", "KE"),
            "Africa/Casablanca": ("Casablanca", "Morocco", "MA"),
        ]

        mappings = knownMappings

        // Add remaining system timezones
        for identifier in TimeZone.knownTimeZoneIdentifiers {
            if mappings[identifier] == nil {
                let components = identifier.split(separator: "/")
                if components.count >= 2 {
                    let city = String(components.last!).replacingOccurrences(of: "_", with: " ")
                    let region = String(components.first!)
                    let countryCode = regionToCountryCode(region)
                    mappings[identifier] = (city, region, countryCode)
                }
            }
        }

        return mappings
    }

    private static func regionToCountryCode(_ region: String) -> String {
        switch region {
        case "America": return "US"
        case "Europe": return "EU"
        case "Asia": return "CN"
        case "Australia": return "AU"
        case "Africa": return "ZA"
        case "Pacific": return "NZ"
        case "Atlantic": return "PT"
        case "Indian": return "IN"
        case "Antarctica": return "AQ"
        default: return "UN"
        }
    }
}
