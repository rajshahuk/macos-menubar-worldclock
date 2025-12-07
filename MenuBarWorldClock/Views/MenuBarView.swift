import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    var openPreferences: () -> Void

    var body: some View {
        ForEach(appState.timezones) { timezone in
            let isPrimary = appState.isPrimary(timezone)
            let time = appState.formattedTime(for: timezone)
            let dayOffset = appState.dayOffsetString(for: timezone)
            let hourOffset = appState.settings.showTimezoneOffset ? appState.hourOffset(for: timezone) : nil
            let label = formatMenuLabel(
                flag: timezone.flagEmoji,
                city: timezone.cityName,
                time: time,
                dayOffset: dayOffset,
                hourOffset: hourOffset
            )

            Button(action: {
                if !isPrimary {
                    appState.setPrimaryTimezone(timezone)
                }
            }) {
                Text(label)
                    .font(.system(.body, design: .monospaced))
            }
            .disabled(isPrimary)
        }

        Divider()

        Button("Preferences...") {
            openPreferences()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private func formatMenuLabel(flag: String, city: String, time: String, dayOffset: String?, hourOffset: String?) -> String {
        let paddedCity = city.padding(toLength: 14, withPad: " ", startingAt: 0)
        var result = "\(flag) \(paddedCity) \(time)"

        if let hourOff = hourOffset {
            result += "  (\(hourOff))"
        }

        if let dayOff = dayOffset {
            result += "  \(dayOff)"
        }

        return result
    }
}
