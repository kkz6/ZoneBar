import SwiftUI

struct AppearancePane: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        SettingsPane(section: .appearance) {
            SettingsGroup {
                SegmentedRow(title: "Theme", selection: $settings.theme, options: [
                    .init(value: .system, title: "System", symbol: "circle.lefthalf.filled"),
                    .init(value: .light, title: "Light", symbol: "sun.max"),
                    .init(value: .dark, title: "Dark", symbol: "moon"),
                ])
            }

            Text("Choose how ZoneBar follows your system appearance.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, DS.Spacing.xs)
        }
    }
}
