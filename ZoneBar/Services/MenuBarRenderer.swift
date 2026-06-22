import Foundation

/// Pure rendering of the menu bar string. Kept free of UI and global state so
/// it can be unit-tested in isolation.
enum MenuBarRenderer {
    static func text(
        for clocks: [WorldClock],
        at now: Date,
        is24Hour: Bool,
        compact: Bool,
        showDate: Bool,
        showDayNightIcon: Bool,
        separator: SeparatorStyle
    ) -> String {
        let visible = clocks.filter(\.showInMenuBar)
        guard !visible.isEmpty else { return "" }

        return visible.map { clock in
            var parts: [String] = []
            if showDayNightIcon {
                parts.append(clock.isDaytime(at: now) ? "☀" : "☾")
            }
            parts.append(compact ? clock.compactName : clock.name)
            parts.append(clock.formattedTime(at: now, is24Hour: is24Hour))
            if showDate {
                parts.append(clock.formattedDate(at: now))
            }
            return parts.joined(separator: " ")
        }
        .joined(separator: separator.value)
    }
}
