import Testing
import Foundation
@testable import ZoneBar

struct MenuBarRendererTests {
    // Fixed instant: 2024-01-01 12:00:00 UTC
    private let now = Date(timeIntervalSince1970: 1_704_110_400)

    private func clock(_ name: String, _ tz: String, menuBar: Bool = true) -> WorldClock {
        WorldClock(name: name, country: "", timezone: tz, showInMenuBar: menuBar)
    }

    @Test func emptyWhenNoClocks() {
        let text = MenuBarRenderer.text(for: [], at: now, is24Hour: true, compact: false, showDate: false, showDayNightIcon: false, separator: .spaces)
        #expect(text.isEmpty)
    }

    @Test func emptyWhenNoneVisible() {
        let clocks = [clock("Tokyo", "Asia/Tokyo", menuBar: false)]
        let text = MenuBarRenderer.text(for: clocks, at: now, is24Hour: true, compact: false, showDate: false, showDayNightIcon: false, separator: .spaces)
        #expect(text.isEmpty)
    }

    @Test func rendersNameAndTime24Hour() {
        let clocks = [clock("London", "Europe/London")]
        let text = MenuBarRenderer.text(for: clocks, at: now, is24Hour: true, compact: false, showDate: false, showDayNightIcon: false, separator: .spaces)
        #expect(text == "London 12:00")
    }

    @Test func twelveHourFormat() {
        let clocks = [clock("London", "Europe/London")]
        let text = MenuBarRenderer.text(for: clocks, at: now, is24Hour: false, compact: false, showDate: false, showDayNightIcon: false, separator: .spaces)
        #expect(text.contains("12:00") && text.contains("PM"))
    }

    @Test func compactNameAbbreviates() {
        let clocks = [clock("New York", "America/New_York")]
        let text = MenuBarRenderer.text(for: clocks, at: now, is24Hour: true, compact: true, showDate: false, showDayNightIcon: false, separator: .spaces)
        #expect(text.hasPrefix("NY "))
    }

    @Test func onlyVisibleClocksRendered() {
        let clocks = [
            clock("London", "Europe/London"),
            clock("Tokyo", "Asia/Tokyo", menuBar: false),
        ]
        let text = MenuBarRenderer.text(for: clocks, at: now, is24Hour: true, compact: false, showDate: false, showDayNightIcon: false, separator: .spaces)
        #expect(text.contains("London"))
        #expect(!text.contains("Tokyo"))
    }

    @Test func separatorJoinsMultipleClocks() {
        let clocks = [clock("London", "Europe/London"), clock("UTC", "UTC")]
        let text = MenuBarRenderer.text(for: clocks, at: now, is24Hour: true, compact: false, showDate: false, showDayNightIcon: false, separator: .pipe)
        #expect(text.contains("|"))
    }

    @Test func dayNightIconPrefix() {
        let clocks = [clock("London", "Europe/London")] // noon → day
        let text = MenuBarRenderer.text(for: clocks, at: now, is24Hour: true, compact: false, showDate: false, showDayNightIcon: true, separator: .spaces)
        #expect(text.hasPrefix("☀"))
    }
}
