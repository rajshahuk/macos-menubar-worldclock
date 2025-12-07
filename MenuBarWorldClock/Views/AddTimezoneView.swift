import SwiftUI

struct AddTimezoneView: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [TimezoneSearchResult] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Timezone")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                .accessibilityLabel("Done")
                .accessibilityHint("Close this dialog")
            }
            .padding()

            Divider()

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                TextField("Search for a city...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(query: newValue)
                    }
                    .accessibilityLabel("Search for a city")
                    .accessibilityHint("Type a city name to find timezones")
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Clear the search field")
                }
            }
            .padding()
            .background(Color(nsColor: .textBackgroundColor))

            Divider()

            // Results
            if searchText.isEmpty {
                VStack {
                    Spacer()
                    Text("Type to search for a city")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if searchResults.isEmpty {
                VStack {
                    Spacer()
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .accessibilityLabel("No results found for \(searchText)")
                    Spacer()
                }
            } else {
                List(searchResults) { result in
                    SearchResultRow(result: result) {
                        addTimezone(result)
                    }
                }
                .listStyle(.plain)
                .accessibilityLabel("Search results")
                .accessibilityHint("\(searchResults.count) timezones found")
            }
        }
        .frame(width: 400, height: 450)
    }

    private func performSearch(query: String) {
        let existingIdentifiers = Set(appState.timezones.map { $0.timezoneIdentifier })
        searchResults = appState.searchTimezones(query: query)
            .filter { !existingIdentifiers.contains($0.timezoneIdentifier) }
    }

    private func addTimezone(_ result: TimezoneSearchResult) {
        let entry = result.toWorldClockEntry()
        appState.addTimezone(entry)
        isPresented = false
    }
}

struct SearchResultRow: View {
    let result: TimezoneSearchResult
    let onAdd: () -> Void

    var body: some View {
        HStack {
            Text(result.flagEmoji)
                .font(.title2)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(result.cityName)
                    .fontWeight(.medium)
                Text("\(result.countryName) • \(result.timezoneIdentifier)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(result.cityName)")
            .accessibilityHint("Add \(result.cityName), \(result.countryName) to your timezone list")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onAdd()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.cityName), \(result.countryName)")
        .accessibilityHint("Double-tap to add this timezone")
        .accessibilityAddTraits(.isButton)
    }
}
