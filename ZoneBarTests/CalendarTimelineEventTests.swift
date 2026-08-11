import Foundation
import Testing
@testable import ZoneBar

struct CalendarTimelineEventTests {
    @Test func eventRangeUsesMinutesWithinTheSelectedDay() throws {
        let calendar = utcCalendar
        let day = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 11
        )))
        let event = CalendarTimelineEvent(
            id: "meeting",
            title: "Planning",
            startDate: day.addingTimeInterval(9.5 * 60 * 60),
            endDate: day.addingTimeInterval(10.25 * 60 * 60),
            calendarName: "Work"
        )

        let range = try #require(event.minuteRange(on: day, calendar: calendar))
        #expect(range.lowerBound == 570)
        #expect(range.upperBound == 615)
    }

    @Test func eventRangeClipsEventsAtDayBoundaries() throws {
        let calendar = utcCalendar
        let day = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 11
        )))
        let event = CalendarTimelineEvent(
            id: "overnight",
            title: "Overnight maintenance",
            startDate: day.addingTimeInterval(-30 * 60),
            endDate: day.addingTimeInterval(30 * 60),
            calendarName: "Work"
        )

        let range = try #require(event.minuteRange(on: day, calendar: calendar))
        #expect(range.lowerBound == 0)
        #expect(range.upperBound == 30)
    }

    @Test func eventContainmentExcludesTheEndBoundary() {
        let start = Date(timeIntervalSince1970: 100)
        let end = Date(timeIntervalSince1970: 200)
        let event = CalendarTimelineEvent(
            id: "event",
            title: "Event",
            startDate: start,
            endDate: end,
            calendarName: "Work"
        )

        #expect(event.contains(start))
        #expect(event.contains(Date(timeIntervalSince1970: 199)))
        #expect(!event.contains(end))
    }

    @Test func calendarURLTargetsTheSpecificEventAndEncodesItsIdentifier() throws {
        let event = CalendarTimelineEvent(
            id: "row-id",
            eventIdentifier: "event id/with separators",
            title: "Planning",
            startDate: Date(timeIntervalSince1970: 100),
            endDate: Date(timeIntervalSince1970: 200),
            calendarName: "Work"
        )

        let url = try #require(CalendarEventService.calendarURL(for: event))
        let components = try #require(URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ))

        #expect(components.scheme == "ical")
        #expect(components.host == "ekevent")
        #expect(components.path == "/event id/with separators")
        #expect(components.queryItems == [
            URLQueryItem(name: "method", value: "show"),
            URLQueryItem(name: "options", value: "more"),
        ])
    }

    @Test func calendarURLRequiresAnEventKitIdentifier() {
        let event = CalendarTimelineEvent(
            id: "row-id",
            title: "Planning",
            startDate: Date(timeIntervalSince1970: 100),
            endDate: Date(timeIntervalSince1970: 200),
            calendarName: "Work"
        )

        #expect(CalendarEventService.calendarURL(for: event) == nil)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
