import Testing
import Foundation
@testable import ZoneBar

struct WorldClockTests {
    // 2024-01-01 12:00:00 UTC
    private let noonUTC = Date(timeIntervalSince1970: 1_704_110_400)
    // 2024-01-01 02:00:00 UTC
    private let earlyUTC = Date(timeIntervalSince1970: 1_704_074_400)

    @Test func formattedTime24Hour() {
        let clock = WorldClock(name: "UTC", country: "", timezone: "UTC")
        #expect(clock.formattedTime(at: noonUTC, is24Hour: true) == "12:00")
    }

    @Test func formattedTimeWithSeconds() {
        let clock = WorldClock(name: "UTC", country: "", timezone: "UTC")
        #expect(clock.formattedTime(at: noonUTC, is24Hour: true, includeSeconds: true) == "12:00:00")
    }

    @Test func twelveHourTimeUsesSelectedLocale() {
        let clock = WorldClock(name: "UTC", country: "", timezone: "UTC")

        let english = clock.formattedTime(
            at: noonUTC,
            is24Hour: false,
            locale: Locale(identifier: "en")
        )
        let japanese = clock.formattedTime(
            at: noonUTC,
            is24Hour: false,
            locale: Locale(identifier: "ja")
        )

        #expect(english.contains("PM"))
        #expect(japanese.contains("午後"))
    }

    @Test func invalidTimezoneFallsBack() {
        let clock = WorldClock(name: "Nowhere", country: "", timezone: "Not/AZone")
        #expect(clock.formattedTime(at: noonUTC, is24Hour: true) == "--:--")
    }

    @Test func daytimeDetection() {
        let utc = WorldClock(name: "UTC", country: "", timezone: "UTC")
        #expect(utc.isDaytime(at: noonUTC) == true)
        #expect(utc.isDaytime(at: earlyUTC) == false)
    }

    @Test func workingHours() {
        let utc = WorldClock(name: "UTC", country: "", timezone: "UTC")
        #expect(utc.isInWorkingHours(at: noonUTC) == true)
        #expect(utc.isInWorkingHours(at: earlyUTC) == false)
    }

    @Test func compactNameMultiWord() {
        let clock = WorldClock(name: "New York", country: "", timezone: "America/New_York")
        #expect(clock.compactName == "NY")
    }

    @Test func compactNameSingleWord() {
        let clock = WorldClock(name: "London", country: "", timezone: "Europe/London")
        #expect(clock.compactName == "LON")
    }

    @Test func compactNameUsesCuratedAbbreviation() {
        let clock = WorldClock(
            name: "Tokyo",
            country: "JP",
            timezone: "Asia/Tokyo",
            abbreviation: "TKY"
        )
        #expect(clock.compactName == "TKY")
    }

    @Test func gmtOffsetWholeHour() {
        let clock = WorldClock(name: "UTC", country: "", timezone: "UTC")
        #expect(clock.gmtOffsetString == "GMT+0")
    }

    @Test func gmtOffsetHalfHour() {
        let clock = WorldClock(name: "India", country: "", timezone: "Asia/Kolkata")
        #expect(clock.gmtOffsetString == "GMT+5:30")
    }

    @Test func relativeDayLabelSameDayIsNil() {
        let clock = WorldClock(name: "UTC", country: "", timezone: "UTC")
        // For UTC-local machines this is nil; for others it still must not crash.
        _ = clock.relativeDayLabel(at: noonUTC)
    }
}
