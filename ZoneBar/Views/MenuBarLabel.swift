import SwiftUI

struct MenuBarLabel: View {
    let store: ClockStore
    let settings: AppSettings
    let ticker: TimeTicker

    var body: some View {
        let text = MenuBarRenderer.text(
            for: store.clocks,
            at: ticker.now,
            is24Hour: settings.is24Hour,
            compact: settings.compactMode,
            showDate: settings.showDate,
            showDayNightIcon: settings.showDayNightIcon,
            separator: settings.separatorStyle,
            locale: settings.locale
        )

        Group {
            if text.isEmpty {
                Image(systemName: "clock")
            } else {
                Text(text)
            }
        }
        .background(StatusItemConfigurator().frame(width: 0, height: 0))
    }
}
