import SwiftUI
import ServiceManagement
import AppKit
import Combine

@main
struct WorldClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var appState: AppState!
    private var cancellables = Set<AnyCancellable>()
    private var preferencesWindow: NSWindow?
    private var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Create menu
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        // Update the status item title
        updateStatusItemTitle()

        // Observe appState changes
        appState.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemTitle()
            }
            .store(in: &cancellables)

        // Start timer to update title every second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItemTitle()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
    }

    private func updateStatusItemTitle() {
        guard let primary = appState.primaryTimezone else {
            statusItem.button?.title = "🕐"
            statusItem.button?.setAccessibilityLabel("World Clock")
            return
        }

        let time = appState.formattedTime(for: primary)
        let fixedWidthTime = makeFixedWidthTime(time)
        let offsetText = appState.settings.showTimezoneOffset ? " (\(appState.hourOffset(for: primary)))" : ""
        let locationPart = formatLocationPart(flag: primary.flagEmoji, city: primary.cityName)
        statusItem.button?.title = "\(locationPart)  \(fixedWidthTime)\(offsetText)"

        // Accessibility: provide a clear description for VoiceOver
        let accessibilityLabel = "World Clock: \(primary.cityName), \(time)"
        statusItem.button?.setAccessibilityLabel(accessibilityLabel)
        statusItem.button?.setAccessibilityHelp("Click to see all configured timezones")
    }

    private func formatLocationPart(flag: String, city: String) -> String {
        switch appState.settings.displayMode {
        case .flagOnly:
            return flag
        case .locationOnly:
            return city
        case .both:
            return "\(flag) \(city)"
        }
    }

    private func makeFixedWidthTime(_ time: String) -> String {
        var result = ""
        for char in time {
            if let digit = char.wholeNumberValue {
                let sansSerifDigit = Character(UnicodeScalar(0x1D7E2 + digit)!)
                result.append(sansSerifDigit)
            } else {
                result.append(char)
            }
        }
        return result
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        // Calculate column widths based on current data
        let columnWidths = calculateColumnWidths()

        // Add timezone items
        for timezone in appState.timezones {
            let isPrimary = appState.isPrimary(timezone)
            let time = appState.formattedTime(for: timezone)
            let dayOffset = appState.dayOffsetString(for: timezone)
            let hourOffset = appState.settings.showTimezoneOffset ? appState.hourOffset(for: timezone) : nil

            let item = NSMenuItem(title: "", action: #selector(selectTimezone(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = timezone.id

            // Create attributed string with tab stops for grid alignment
            item.attributedTitle = createMenuItemAttributedString(
                isPrimary: isPrimary,
                flag: timezone.flagEmoji,
                city: timezone.cityName,
                time: time,
                hourOffset: hourOffset,
                dayOffset: dayOffset,
                columnWidths: columnWidths
            )

            // Accessibility: provide clear description for VoiceOver
            let accessibilityDescription = formatAccessibilityLabel(
                city: timezone.cityName,
                time: time,
                dayOffset: dayOffset,
                hourOffset: hourOffset,
                isPrimary: isPrimary
            )
            item.setAccessibilityLabel(accessibilityDescription)

            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        prefsItem.setAccessibilityHelp("Open preferences to manage timezones and settings")
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        quitItem.setAccessibilityHelp("Quit MenuBar World Clock")
        menu.addItem(quitItem)
    }

    private func formatAccessibilityLabel(city: String, time: String, dayOffset: String?, hourOffset: String?, isPrimary: Bool) -> String {
        var parts = [String]()

        if isPrimary {
            parts.append("\(city), currently selected")
        } else {
            parts.append(city)
        }

        parts.append("time: \(time)")

        if let hourOff = hourOffset {
            if hourOff == "0" {
                parts.append("same time as your timezone")
            } else if hourOff.hasPrefix("+") {
                parts.append("\(hourOff.dropFirst()) hours ahead")
            } else {
                parts.append("\(hourOff.dropFirst()) hours behind")
            }
        }

        if let dayOff = dayOffset {
            parts.append(dayOff)
        }

        parts.append("click to select as primary")

        return parts.joined(separator: ", ")
    }

    private struct ColumnWidths {
        let location: CGFloat
        let time: CGFloat
        let offset: CGFloat
    }

    private func getMenuFont() -> NSFont {
        if appState.settings.useMonospacedFont {
            return NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        } else {
            return NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
    }

    private func calculateColumnWidths() -> ColumnWidths {
        let font = getMenuFont()
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        // Find the longest location string
        var maxLocationWidth: CGFloat = 0
        for timezone in appState.timezones {
            let locationText: String
            switch appState.settings.displayMode {
            case .flagOnly:
                locationText = timezone.flagEmoji
            case .locationOnly:
                locationText = timezone.cityName
            case .both:
                locationText = "\(timezone.flagEmoji) \(timezone.cityName)"
            }
            let width = (locationText as NSString).size(withAttributes: attributes).width
            maxLocationWidth = max(maxLocationWidth, width)
        }

        // Find the longest time string
        var maxTimeWidth: CGFloat = 0
        for timezone in appState.timezones {
            let time = appState.formattedTime(for: timezone)
            let width = (time as NSString).size(withAttributes: attributes).width
            maxTimeWidth = max(maxTimeWidth, width)
        }

        // Find the longest offset string
        var maxOffsetWidth: CGFloat = 0
        if appState.settings.showTimezoneOffset {
            for timezone in appState.timezones {
                let hourOffset = appState.hourOffset(for: timezone)
                let dayOffset = appState.dayOffsetString(for: timezone)
                var offsetText = "(\(hourOffset))"
                if let day = dayOffset {
                    offsetText += "  \(day)"
                }
                let width = (offsetText as NSString).size(withAttributes: attributes).width
                maxOffsetWidth = max(maxOffsetWidth, width)
            }
        } else {
            // Just day offset
            for timezone in appState.timezones {
                if let dayOffset = appState.dayOffsetString(for: timezone) {
                    let width = (dayOffset as NSString).size(withAttributes: attributes).width
                    maxOffsetWidth = max(maxOffsetWidth, width)
                }
            }
        }

        return ColumnWidths(
            location: maxLocationWidth,
            time: maxTimeWidth,
            offset: maxOffsetWidth
        )
    }

    private func createMenuItemAttributedString(
        isPrimary: Bool,
        flag: String,
        city: String,
        time: String,
        hourOffset: String?,
        dayOffset: String?,
        columnWidths: ColumnWidths
    ) -> NSAttributedString {
        let font = getMenuFont()

        // Define tab stop positions
        let checkmarkWidth: CGFloat = 24
        let columnGap: CGFloat = 16
        let locationTabStop = checkmarkWidth
        let timeTabStop = locationTabStop + columnWidths.location + columnGap
        let offsetTabStop = timeTabStop + columnWidths.time + columnGap

        // Create paragraph style with tab stops
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: locationTabStop),
            NSTextTab(textAlignment: .left, location: timeTabStop),
            NSTextTab(textAlignment: .left, location: offsetTabStop)
        ]

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        // Build the string with tabs
        let checkmark = isPrimary ? "✓" : " "
        let locationText: String
        switch appState.settings.displayMode {
        case .flagOnly:
            locationText = flag
        case .locationOnly:
            locationText = city
        case .both:
            locationText = "\(flag) \(city)"
        }

        var offsetText = ""
        if let hourOff = hourOffset {
            offsetText = "(\(hourOff))"
        }
        if let dayOff = dayOffset {
            if !offsetText.isEmpty {
                offsetText += "  \(dayOff)"
            } else {
                offsetText = dayOff
            }
        }

        let menuText = "\(checkmark)\t\(locationText)\t\(time)\t\(offsetText)"

        return NSAttributedString(string: menuText, attributes: attributes)
    }

    @objc private func selectTimezone(_ sender: NSMenuItem) {
        guard let timezoneId = sender.representedObject as? UUID,
              let timezone = appState.timezones.first(where: { $0.id == timezoneId }) else {
            return
        }
        appState.setPrimaryTimezone(timezone)
    }

    @objc private func openPreferences() {
        if let existingWindow = preferencesWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let preferencesView = PreferencesView(appState: appState)
        let hostingController = NSHostingController(rootView: preferencesView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "MenuBar World Clock Preferences"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 500, height: 550))
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .modalPanel

        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
