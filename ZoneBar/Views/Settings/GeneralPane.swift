import SwiftUI

struct GeneralPane: View {
    @Environment(AppSettings.self) private var settings
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        @Bindable var settings = settings

        SettingsPane(section: .general) {
            SettingsGroup {
                SettingRow(title: "Launch at login") {
                    Toggle("", isOn: $launchAtLogin)
                        .zoneToggle()
                        .onChange(of: launchAtLogin) { _, newValue in
                            if !LaunchAtLogin.set(newValue) {
                                launchAtLogin = LaunchAtLogin.isEnabled
                            }
                        }
                }

                SettingRow(title: "Show date in menu bar") {
                    Toggle("", isOn: $settings.showDate)
                        .zoneToggle()
                }

                SegmentedRow(title: "Time format", selection: $settings.is24Hour, options: [
                    .init(value: true, title: "24-hour", glyph: "24"),
                    .init(value: false, title: "12-hour", glyph: "12"),
                ])
            }
        }
        .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
    }
}
