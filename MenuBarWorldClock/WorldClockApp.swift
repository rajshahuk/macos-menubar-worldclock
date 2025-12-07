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
            return
        }

        let time = appState.formattedTime(for: primary)
        let fixedWidthTime = makeFixedWidthTime(time)
        let offsetText = appState.settings.showTimezoneOffset ? " (\(appState.hourOffset(for: primary)))" : ""
        let locationPart = formatLocationPart(flag: primary.flagEmoji, city: primary.cityName)
        statusItem.button?.title = "\(locationPart)  \(fixedWidthTime)\(offsetText)"
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

        // Add timezone items
        for timezone in appState.timezones {
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

            let item = NSMenuItem(title: label, action: isPrimary ? nil : #selector(selectTimezone(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = timezone.id
            item.isEnabled = !isPrimary

            // Use monospaced font
            let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            item.attributedTitle = NSAttributedString(string: label, attributes: attributes)

            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func formatMenuLabel(flag: String, city: String, time: String, dayOffset: String?, hourOffset: String?) -> String {
        var result: String

        switch appState.settings.displayMode {
        case .flagOnly:
            result = "\(flag)  \(time)"
        case .locationOnly:
            let paddedCity = city.padding(toLength: 14, withPad: " ", startingAt: 0)
            result = "\(paddedCity) \(time)"
        case .both:
            let paddedCity = city.padding(toLength: 14, withPad: " ", startingAt: 0)
            result = "\(flag) \(paddedCity) \(time)"
        }

        if let hourOff = hourOffset {
            result += "  (\(hourOff))"
        }

        if let dayOff = dayOffset {
            result += "  \(dayOff)"
        }

        return result
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
        window.setContentSize(NSSize(width: 450, height: 350))
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
