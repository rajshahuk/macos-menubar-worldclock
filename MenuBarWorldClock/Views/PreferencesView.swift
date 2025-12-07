import SwiftUI

struct PreferencesView: View {
    @ObservedObject var appState: AppState
    @State private var showingAddTimezone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Timezones Section
            TimezonesSection(appState: appState, showingAddTimezone: $showingAddTimezone)

            Divider()

            // Settings Section
            SettingsSection(appState: appState)
        }
        .padding()
        .frame(width: 500, height: 550)
        .sheet(isPresented: $showingAddTimezone) {
            AddTimezoneView(appState: appState, isPresented: $showingAddTimezone)
        }
    }
}

struct TimezonesSection: View {
    @ObservedObject var appState: AppState
    @Binding var showingAddTimezone: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timezones")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            List {
                ForEach(appState.timezones) { timezone in
                    TimezoneRow(
                        timezone: timezone,
                        canRemove: appState.timezones.count > 1,
                        onRemove: {
                            appState.removeTimezone(timezone)
                        }
                    )
                }
                .onMove { source, destination in
                    appState.moveTimezone(from: source, to: destination)
                }
            }
            .listStyle(.bordered)
            .frame(height: 200)
            .accessibilityLabel("Timezone list")
            .accessibilityHint("Contains \(appState.timezones.count) timezones. Use drag and drop to reorder.")

            HStack {
                Button(action: {
                    showingAddTimezone = true
                }) {
                    Label("Add Timezone", systemImage: "plus")
                }
                .accessibilityHint("Opens a search dialog to add a new timezone")

                Spacer()

                Text("Drag to reorder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

struct TimezoneRow: View {
    let timezone: WorldClockEntry
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(timezone.flagEmoji)
                .font(.title2)
                .accessibilityHidden(true) // Hide flag from VoiceOver, included in row label

            VStack(alignment: .leading) {
                Text(timezone.cityName)
                Text(timezone.timezoneIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(timezone.cityName)")
                .accessibilityHint("Double-tap to remove this timezone from your list")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timezone.cityName), \(timezone.timezoneIdentifier)")
        .accessibilityHint("Drag to reorder")
    }
}

struct SettingsSection: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 12) {
                // Display mode
                HStack {
                    Text("Display:")
                        .frame(width: 80, alignment: .leading)
                    Picker("Display", selection: Binding(
                        get: { appState.settings.displayMode },
                        set: { appState.setDisplayMode($0) }
                    )) {
                        ForEach(DisplayMode.allCases, id: \.self) { mode in
                            Text(mode.description).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .help("Choose what to display: flag, location name, or both")
                }

                // Time format
                HStack(alignment: .top) {
                    Text("Time Format:")
                        .frame(width: 80, alignment: .leading)
                    Picker("Time Format", selection: Binding(
                        get: { appState.settings.use24HourFormat },
                        set: { appState.setUse24HourFormat($0) }
                    )) {
                        Text("24-hour (14:30)").tag(true)
                        Text("12-hour (2:30 PM)").tag(false)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }

                // Toggles
                HStack {
                    Text("")
                        .frame(width: 80, alignment: .leading)
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show Seconds", isOn: Binding(
                            get: { appState.settings.showSeconds },
                            set: { appState.setShowSeconds($0) }
                        ))
                        .help("Display seconds in the time (e.g., 14:30:45)")

                        Toggle("Show Timezone Offset", isOn: Binding(
                            get: { appState.settings.showTimezoneOffset },
                            set: { appState.setShowTimezoneOffset($0) }
                        ))
                        .help("Display hours offset from your timezone (e.g., +2, -5)")

                        Toggle("Launch at Login", isOn: Binding(
                            get: { appState.settings.launchAtLogin },
                            set: { appState.setLaunchAtLogin($0) }
                        ))
                        .help("Automatically start World Clock when you log in")
                    }
                }
            }
        }
    }
}
