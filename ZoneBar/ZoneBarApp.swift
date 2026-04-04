import SwiftUI

@main
struct ZoneBarApp: App {
    @StateObject private var clockManager = ClockManager.shared
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    var body: some Scene {
        MenuBarExtra {
            ClockListView(clockManager: clockManager)
                .preferredColorScheme(colorScheme)
        } label: {
            MenuBarLabel(clockManager: clockManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
