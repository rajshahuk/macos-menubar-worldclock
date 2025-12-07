# MenuBar World Clock

A lightweight macOS menubar application that displays the current time in different timezones around the world.

![macOS](https://img.shields.io/badge/macOS-15.0+-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menubar Integration** - Lives in your menubar showing flag, city name, and current time
- **Multiple Timezones** - Track as many timezones as you need
- **Real-time Updates** - Time updates every second
- **Day Offset Indicator** - Clearly shows when a timezone is on a different day (+1 day / -1 day)
- **Timezone Offset** - Optionally display hours offset from your local timezone (e.g., +5.5, -8)
- **City Search** - Find and add timezones by searching for city names
- **Drag to Reorder** - Organize your timezone list by dragging
- **Display Modes** - Show flag only, location name only, or both
- **12/24 Hour Format** - Choose your preferred time display format
- **Show Seconds** - Optionally display seconds in the time
- **Launch at Login** - Optionally start World Clock when you log in
- **Accessible** - Full VoiceOver support for screen reader users
- **Native macOS Design** - Built with SwiftUI and AppKit, supports light and dark mode

## Screenshots

*Menubar showing selected timezone:*
```
🇬🇧 London  𝟏𝟒:𝟑𝟐:𝟎𝟓
```

*Dropdown menu:*
```
🇬🇧 London        14:32:05  (+0)
🇺🇸 New York      09:32:05  (-5)
🇭🇰 Hong Kong     22:32:05  (+8)   +1 day
🇮🇳 Mumbai        20:02:05  (+5.5)
─────────────────────────
Preferences...
Quit
```

## Requirements

- macOS 15.0 (Sequoia) or later
- Xcode 16.0+ (for building)

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/macos-menubar-worldclock.git
   cd macos-menubar-worldclock
   ```

2. Build using Xcode:
   ```bash
   xcodebuild -project MenuBarWorldClock.xcodeproj -scheme MenuBarWorldClock -configuration Release build
   ```

   Or open in Xcode:
   ```bash
   open MenuBarWorldClock.xcodeproj
   ```

3. The built app will be in `build/Release/MenuBarWorldClock.app`

4. Move to Applications folder:
   ```bash
   mv build/Release/MenuBarWorldClock.app /Applications/
   ```

### Using Swift Package Manager

For development/testing purposes:
```bash
swift build
swift run
```

## Usage

### First Launch

On first launch, MenuBar World Clock comes pre-configured with these timezones:
- Your local timezone (set as primary)
- Hong Kong
- Mumbai
- London, UK
- New York, USA

### Changing the Primary Timezone

Click on any timezone in the dropdown menu to set it as the primary. The primary timezone is displayed in the menubar.

### Adding Timezones

1. Click the menubar icon
2. Select "Preferences..."
3. Click "Add Timezone"
4. Search for a city name
5. Click the + button to add it

### Removing Timezones

1. Open Preferences
2. Click the X button next to the timezone you want to remove

Note: You cannot remove the last timezone - at least one must remain.

### Reordering Timezones

In the Preferences window, drag timezones to reorder them. The order is reflected in the dropdown menu.

### Settings

- **Display**: Choose to show flag only, location name only, or both
- **Time Format**: Toggle between 12-hour (2:30 PM) and 24-hour (14:30) format
- **Show Seconds**: Display seconds in the time (e.g., 14:30:45)
- **Show Timezone Offset**: Display hours offset from your timezone (e.g., +8, -5, +5.5)
- **Launch at Login**: Enable to automatically start World Clock when you log in

## Project Structure

```
MenuBarWorldClock/
├── WorldClockApp.swift              # App entry point and menu bar integration
├── AppState.swift                   # Main view model
├── Models/
│   ├── WorldClockEntry.swift        # Timezone data model
│   └── AppSettings.swift            # User preferences model
├── Services/
│   ├── PreferencesService.swift     # UserDefaults persistence
│   ├── TimezoneService.swift        # Time formatting & city search
│   └── LaunchAtLoginService.swift   # Login item management
├── Views/
│   ├── PreferencesView.swift        # Preferences window
│   └── AddTimezoneView.swift        # City search sheet
├── Info.plist
└── WorldClock.entitlements

MenuBarWorldClockTests/
├── WorldClockEntryTests.swift       # Model tests
├── TimezoneServiceTests.swift       # Time service tests
├── PreferencesServiceTests.swift    # Persistence tests
└── AppStateTests.swift              # View model tests
```

## Architecture

The app follows MVVM architecture with dependency injection for testability:

- **Models**: Pure data structures (`WorldClockEntry`, `AppSettings`, `DisplayMode`)
- **Services**: Business logic with protocol abstractions
  - `PreferencesServiceProtocol` - Data persistence
  - `TimezoneServiceProtocol` - Time formatting and search
  - `LaunchAtLoginServiceProtocol` - System integration
- **AppState**: Main view model that coordinates services and exposes state to views
- **Views**: SwiftUI views for preferences; AppKit NSMenu for the dropdown menu

## Testing

Run tests using Xcode:
```bash
xcodebuild test -project MenuBarWorldClock.xcodeproj -scheme MenuBarWorldClock
```

Or via Swift Package Manager:
```bash
swift test
```

The test suite includes 71 tests covering:
- Unit tests for data models
- Unit tests for services with mock dependencies
- Integration tests for AppState with mock services
- Settings persistence tests
- Timezone offset calculation tests

## Configuration

User preferences are stored in UserDefaults under the following keys:
- `worldclock.timezones` - Array of configured timezones
- `worldclock.settings` - App settings (time format, display mode, show seconds, show timezone offset, launch at login, primary timezone)

Bundle identifier: `com.12nines.menubarworldclock`

## Accessibility

MenuBar World Clock is fully accessible with VoiceOver:
- Menu bar button announces the current city and time
- Dropdown menu items provide detailed descriptions including timezone offsets and day changes
- Preferences window includes proper labels, hints, and semantic structure
- All interactive elements are keyboard accessible

## Supported Timezones

World Clock uses the macOS system timezone database (`TimeZone.knownTimeZoneIdentifiers`), which includes hundreds of cities worldwide. Common cities have enhanced metadata for better search results.

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- Flag emojis provided by Unicode standard
- Timezone data from macOS system database
