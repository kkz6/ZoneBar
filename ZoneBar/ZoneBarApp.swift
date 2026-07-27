import SwiftUI

@main
struct ZoneBarApp: App {
    @State private var store = ClockStore()
    @State private var settings = AppSettings()
    @State private var ticker = TimeTicker()
    @State private var updater = AppUpdater()

    var body: some Scene {
        MenuBarExtra {
            ClockPopover()
                .environment(store)
                .environment(settings)
                .environment(ticker)
                .environment(updater)
                .environment(\.locale, settings.locale)
                .tint(.zoneAccent)
                .preferredColorScheme(settings.theme.colorScheme)
        } label: {
            MenuBarLabel(store: store, settings: settings, ticker: ticker)
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: SettingsWindow.windowID) {
            SettingsWindow()
                .environment(store)
                .environment(settings)
                .environment(ticker)
                .environment(updater)
                .environment(\.locale, settings.locale)
                .tint(.zoneAccent)
                .preferredColorScheme(settings.theme.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 560)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .appSettings) {
                OpenSettingsButton(updater: updater)
            }
        }
    }
}

/// Menu command (⌘,) that opens the custom settings window.
private struct OpenSettingsButton: View {
    @Environment(\.openWindow) private var openWindow
    let updater: AppUpdater

    var body: some View {
        Group {
            Button("Check for Updates…") {
                updater.checkForUpdates()
            }

            Divider()

            Button("Settings…") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openWindow(id: SettingsWindow.windowID)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
