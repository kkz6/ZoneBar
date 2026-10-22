import EventKit
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

    @Test(arguments: ["Out of office", "  OUT OF OFFICE  ", "Out-of-office", "OOO", "不在"])
    func recognizesStandardAbsenceTitles(_ title: String) {
        #expect(CalendarTimelineEvent.Kind.classify(title: title, availability: .busy) == .unavailable)
    }

    @Test(arguments: ["Out of office handover", "OOO planning", "Vacation planning", "Focus time", "", "Team meeting"])
    func regularMeetingsAreNotClassifiedAsAbsences(_ title: String) {
        #expect(CalendarTimelineEvent.Kind.classify(title: title, availability: .busy) == .event)
    }

    @Test(arguments: [
        "Karthick — OOO", "OOO - Karthick", "Out of office (afternoon)",
        "Out of office: family appointment", "[OOO] Karthick", "O.O.O.",
        "out–of–office", "OUT—OF—OFFICE", "out\tof\toffice", "ＯＯＯ",
        "PTO", "P.T.O. — Karthick", "Karthick's PTO", "Paid time off",
        "Annual leave - Karthick", "Sick leave (AM)", "Parental leave",
        "Maternity leave", "Paternity leave", "On leave today", "On vacation"
    ])
    func recognizesDecoratedAbsenceAndLeaveTitles(_ title: String) {
        #expect(CalendarTimelineEvent.Kind.classify(title: title, availability: .busy) == .unavailable)
    }

    @Test(arguments: [
        "OOO - handover", "Out of office policy", "PTO approval", "Annual leave planning",
        "Discuss sick leave", "OOO coverage", "Team sync: PTO", "Paid time off review",
        "Not OOO", "OOO cancelled", "PTO canceled", "Back from PTO", "Returning from annual leave",
        "Return from OOO", "Vacation planning", "Boardroom", "PTOOL demo", "OOOps",
        "Out of officework", "Workout of office", "Leave feedback", "Office relocation",
        "Afternoon appointment", "不在時の引き継ぎ"
    ])
    func avoidsMeetingContextNegationAndPartialWordMatches(_ title: String) {
        #expect(CalendarTimelineEvent.Kind.classify(title: title, availability: .busy) == .event)
    }

    @Test func nativeAvailabilityTakesPriorityOverTitleHeuristics() {
        #expect(CalendarTimelineEvent.Kind.classify(title: "OOO handover", availability: .unavailable) == .unavailable)
    }

    @Test func nativeUnavailableFlagWorksWithCustomTitles() {
        #expect(CalendarTimelineEvent.Kind.classify(title: "Family day", availability: .unavailable) == .unavailable)
        #expect(CalendarTimelineEvent.Kind.classify(title: "Meeting", availability: .free) == .event)
        #expect(CalendarTimelineEvent.Kind.classify(title: "Meeting", availability: .tentative) == .event)
        #expect(CalendarTimelineEvent.Kind.classify(title: "Meeting", availability: .notSupported) == .event)
    }

    @MainActor
    @Test func includesAllDayAbsencesButNotOrdinaryAllDayEvents() throws {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.startDate = Date(timeIntervalSince1970: 100)
        event.endDate = Date(timeIntervalSince1970: 86_500)
        event.isAllDay = true
        event.title = "Annual leave — Karthick"
        let absence = try #require(CalendarTimelineEvent(event: event))
        #expect(absence.kind == .unavailable)
        #expect(absence.isAllDay)
        #expect(absence.contains(Date(timeIntervalSince1970: 1_000)))

        event.title = "Birthday"
        #expect(CalendarTimelineEvent(event: event) == nil)
    }

    @MainActor
    @Test func ignoresInvalidCalendarIntervals() {
        let event = EKEvent(eventStore: EKEventStore())
        event.title = "Meeting"
        #expect(CalendarTimelineEvent(event: event) == nil)
        event.startDate = Date(timeIntervalSince1970: 100)
        event.endDate = event.startDate
        #expect(CalendarTimelineEvent(event: event) == nil)
        event.endDate = Date(timeIntervalSince1970: 99)
        #expect(CalendarTimelineEvent(event: event) == nil)
    }

    @MainActor
    @Test func refreshKeepsAllOverlappingEventsAlongsideAbsences() throws {
        let store = EKEventStore()
        let start = Date(timeIntervalSince1970: 1_792_624_200)
        func makeEvent(_ title: String, offset: Double, duration: Double) -> EKEvent {
            let event = EKEvent(eventStore: store)
            event.title = title
            event.startDate = start.addingTimeInterval(offset)
            event.endDate = event.startDate.addingTimeInterval(duration)
            return event
        }
        let service = CalendarEventService(eventStore: store, accessStateOverride: .connected,
            eventFetcher: { _, _ in [
                makeEvent("Design review", offset: 60, duration: 3_600),
                makeEvent("Karthick — OOO", offset: -3_600, duration: 28_800),
                makeEvent("Planning", offset: 0, duration: 1_800),
                makeEvent("Customer call", offset: 120, duration: 3_600),
                makeEvent("Later", offset: 7_200, duration: 600)
            ] }
        )
        service.refresh(for: start)
        let active = service.events(at: start.addingTimeInterval(300))
        #expect(active.map(\.title) == ["Karthick — OOO", "Planning", "Design review", "Customer call"])
        #expect(active.filter { $0.kind == .event }.count == 3)
        #expect(active.filter { $0.kind == .unavailable }.count == 1)
        #expect(Set(active.map(\.id)).count == 4)
        #expect(!service.events(at: start.addingTimeInterval(1_800)).contains { $0.title == "Planning" })
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
