import SwiftUI

struct MenuBarLabel: View {
    let store: ClockStore
    let settings: AppSettings
    let ticker: TimeTicker
    let focusFilter: FocusClockFilter

    var body: some View {
        let text = MenuBarRenderer.text(
            for: focusFilter.menuBarClocks(from: store.clocks),
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
        .task { await focusFilter.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await focusFilter.refresh() }
        }
    }
}
