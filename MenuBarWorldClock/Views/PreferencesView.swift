import SwiftUI

struct PreferencesView: View {
    @ObservedObject var appState: AppState
    @State private var showingAddTimezone = false

    var body: some View {
        TabView {
            TimezonesTab(appState: appState, showingAddTimezone: $showingAddTimezone)
                .tabItem {
                    Label("Timezones", systemImage: "globe")
                }

            SettingsTab(appState: appState)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .frame(width: 450, height: 350)
        .sheet(isPresented: $showingAddTimezone) {
            AddTimezoneView(appState: appState, isPresented: $showingAddTimezone)
        }
    }
}

struct TimezonesTab: View {
    @ObservedObject var appState: AppState
    @Binding var showingAddTimezone: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configured Timezones")
                .font(.headline)

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

            HStack {
                Button(action: {
                    showingAddTimezone = true
                }) {
                    Label("Add Timezone", systemImage: "plus")
                }

                Spacer()

                Text("Drag to reorder")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
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
                .help("Remove timezone")
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsTab: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Picker("Display", selection: Binding(
                    get: { appState.settings.displayMode },
                    set: { appState.setDisplayMode($0) }
                )) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .help("Choose what to display: flag, location name, or both")
            }

            Section {
                Picker("Time Format", selection: Binding(
                    get: { appState.settings.use24HourFormat },
                    set: { appState.setUse24HourFormat($0) }
                )) {
                    Text("24-hour (14:30)").tag(true)
                    Text("12-hour (2:30 PM)").tag(false)
                }
                .pickerStyle(.radioGroup)

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
            }

            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { appState.settings.launchAtLogin },
                    set: { appState.setLaunchAtLogin($0) }
                ))
                .help("Automatically start World Clock when you log in")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
