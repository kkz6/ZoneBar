import SwiftUI

struct MenuBarPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ClockStore.self) private var store
    @Environment(TimeTicker.self) private var ticker

    var body: some View {
        @Bindable var settings = settings

        SettingsPane(section: SettingsSection.menuBar) {
            SettingsGroup(header: "Preview") {
                HStack {
                    Text(previewText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, SettingsLayout.cardHorizontalInset)
                .frame(minHeight: DS.Size.rowHeight)
            }

            SettingsGroup(header: "Display") {
                SettingRow(title: "Compact city names", subtitle: "New York → NY") {
                    Toggle("", isOn: $settings.compactMode)
                        .settingsToggle()
                }

                SettingsDivider()

                SettingRow(title: "Day / night icon", subtitle: "Prefix each clock with ☀ or ☾") {
                    Toggle("", isOn: $settings.showDayNightIcon)
                        .settingsToggle()
                }

                SettingsDivider()

                SegmentedRow(title: "Separator", selection: $settings.separatorStyle, options: [
                    .init(value: .spaces, title: "Spaces", symbol: "space"),
                    .init(value: .dot, title: "Dot", glyph: "•"),
                    .init(value: .pipe, title: "Pipe", glyph: "|"),
                    .init(value: .slash, title: "Slash", glyph: "/"),
                ])
            }

            SettingsNote(
                text: "Choose which clocks appear in the menu bar from the Clocks section.",
                fontSize: 11
            )
        }
    }

    private var previewText: String {
        let text = MenuBarRenderer.text(
            for: store.clocks,
            at: ticker.now,
            is24Hour: settings.is24Hour,
            compact: settings.compactMode,
            showDate: settings.showDate,
            showDayNightIcon: settings.showDayNightIcon,
            separator: settings.separatorStyle
        )
        return text.isEmpty ? "🕐  (no clocks selected)" : text
    }
}

#if DEBUG
#Preview("Menu Bar") {
    MenuBarPane()
        .settingsPreviewEnvironment()
        .frame(width: 400, height: 520, alignment: .top)
}
#endif
