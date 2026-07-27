import SwiftUI

struct GeneralPane: View {
    @Environment(AppSettings.self) private var settings
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        @Bindable var settings = settings

        SettingsPane(section: SettingsSection.general) {
            SettingsGroup {
                SettingRow(title: "Launch at login") {
                    Toggle("", isOn: $launchAtLogin)
                        .settingsToggle()
                        .onChange(of: launchAtLogin) { _, newValue in
                            if !LaunchAtLogin.set(newValue) {
                                launchAtLogin = LaunchAtLogin.isEnabled
                            }
                        }
                }

                SettingsDivider()

                SettingRow(title: "Show date in menu bar") {
                    Toggle("", isOn: $settings.showDate)
                        .settingsToggle()
                }

                SettingsDivider()

                SegmentedRow(title: "Time format", selection: $settings.is24Hour, options: [
                    .init(value: true, title: "24-hour", glyph: "24"),
                    .init(value: false, title: "12-hour", glyph: "12"),
                ])
            }
        }
        .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
    }
}

#if DEBUG
#Preview("General") {
    GeneralPane()
        .settingsPreviewEnvironment()
        .frame(width: 400, height: 520, alignment: .top)
}
#endif
