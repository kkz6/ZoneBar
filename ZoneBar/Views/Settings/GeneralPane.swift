import SwiftUI

struct GeneralPane: View {
    @Environment(AppSettings.self) private var settings
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        @Bindable var settings = settings

        SettingsPane(section: SettingsSection.general) {
            SettingsGroup {
                SettingRow(title: "Launch at login") {
                    Toggle("", isOn: launchAtLoginBinding)
                        .settingsToggle()
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

            SettingsGroup(header: "Language") {
                SegmentedRow(title: "App language", selection: $settings.language, options: [
                    .init(value: .automatic, title: "Automatic", symbol: "globe"),
                    .init(value: .english, title: "English", glyph: "EN"),
                    .init(value: .japanese, title: "Japanese", glyph: "日本"),
                ])
            }

            SettingsNote(text: "Automatic follows your Mac’s language.")
        }
        .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
    }

    /// Writes to ServiceManagement only from direct toggle interaction.
    /// Synchronizing state in `onAppear` must not re-register the login item.
    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin },
            set: { requestedValue in
                if LaunchAtLogin.set(requestedValue) {
                    launchAtLogin = requestedValue
                } else {
                    launchAtLogin = LaunchAtLogin.isEnabled
                }
            }
        )
    }
}

#if DEBUG
#Preview("General") {
    GeneralPane()
        .settingsPreviewEnvironment()
        .frame(width: 400, height: 520, alignment: .top)
}
#endif
