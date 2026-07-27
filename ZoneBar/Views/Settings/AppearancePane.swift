import SwiftUI

struct AppearancePane: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        SettingsPane(section: SettingsSection.appearance) {
            SettingsGroup {
                SegmentedRow(title: "Theme", selection: $settings.theme, options: [
                    .init(value: .system, title: "System", symbol: "circle.lefthalf.filled"),
                    .init(value: .light, title: "Light", symbol: "sun.max"),
                    .init(value: .dark, title: "Dark", symbol: "moon"),
                ])
            }

            SettingsNote(text: "Choose how ZoneBar follows your system appearance.")
        }
    }
}

#if DEBUG
#Preview("Appearance") {
    AppearancePane()
        .settingsPreviewEnvironment()
        .frame(width: 400, height: 520, alignment: .top)
}
#endif
