import AppKit
import EventKit
import Foundation
import Observation

struct CalendarTimelineEvent: Identifiable, Equatable {
    let id: String
    let eventIdentifier: String?
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarName: String
    let kind: Kind
    let isAllDay: Bool

    enum Kind: Equatable {
        case event
        case unavailable

        static func classify(title: String, availability: EKEventAvailability) -> Self {
            if availability == .unavailable { return .unavailable }

            // EventKit doesn't expose Google's eventType. Title matching is a
            // fallback: require whole words and avoid meetings about absences.
            let words = title.folding(options: [.caseInsensitive, .widthInsensitive],
                                      locale: Locale(identifier: "en_US_POSIX"))
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
            let normalized = " " + words.joined(separator: " ") + " "
            if normalized == " 不在 " { return .unavailable }

            let absenceLabels = [
                "out of office", "ooo", "o o o", "pto", "p t o", "paid time off",
                "annual leave", "sick leave", "parental leave", "maternity leave",
                "paternity leave", "on leave", "on vacation"
            ]
            guard absenceLabels.contains(where: { normalized.contains(" " + $0 + " ") }) else {
                return .event
            }

            let meetingWords: Set<String> = [
                "handover", "handoff", "planning", "plan", "policy", "policies",
                "request", "requests", "approval", "approvals", "discussion", "discuss",
                "review", "meeting", "sync", "coverage", "schedule", "training",
                "not", "cancelled", "canceled", "cancellation"
            ]
            let isReturn = ["back from", "return from", "returning from"]
                .contains { normalized.contains(" " + $0 + " ") }
            return words.contains(where: { meetingWords.contains($0) }) || isReturn
                ? .event : .unavailable
        }
    }

    init(
        id: String,
        eventIdentifier: String? = nil,
        title: String,
        startDate: Date,
        endDate: Date,
        calendarName: String,
        kind: Kind = .event,
        isAllDay: Bool = false
    ) {
        self.id = id
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarName = calendarName
        self.kind = kind
        self.isAllDay = isAllDay
    }

    init?(event: EKEvent) {
        let title = event.title ?? ""
        let kind = Kind.classify(title: title, availability: event.availability)
        guard event.status != .canceled,
              !event.isAllDay || kind == .unavailable,
              let start = event.startDate, let end = event.endDate,
              start < end else { return nil }

        let sourceID = event.eventIdentifier ?? event.calendarItemExternalIdentifier ?? "event"
        self.init(
            id: "\(event.calendar?.calendarIdentifier ?? "")-\(sourceID)-\(start.timeIntervalSinceReferenceDate)",
            eventIdentifier: event.eventIdentifier,
            title: title,
            startDate: start,
            endDate: end,
            calendarName: event.calendar?.title ?? "",
            kind: kind,
            isAllDay: event.isAllDay
        )
    }

    func contains(_ date: Date) -> Bool {
        startDate <= date && date < endDate
    }

    func minuteRange(on date: Date, calendar: Calendar = .current) -> ClosedRange<Double>? {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return nil
        }

        let clippedStart = max(startDate, dayStart)
        let clippedEnd = min(endDate, dayEnd)
        guard clippedStart < clippedEnd else { return nil }

        let startMinute = clippedStart.timeIntervalSince(dayStart) / 60
        let endMinute = min(1439, clippedEnd.timeIntervalSince(dayStart) / 60)
        return max(0, startMinute)...max(startMinute, endMinute)
    }
}

enum CalendarAccessState: Equatable {
    case notDetermined
    case connected
    case denied
    case restricted
    case writeOnly

    var canReadEvents: Bool { self == .connected }
}

@MainActor
@Observable
final class CalendarEventService {
    private(set) var accessState: CalendarAccessState
    private(set) var events: [CalendarTimelineEvent] = []
    private(set) var isRequestingAccess = false
    private(set) var lastError: String?

    @ObservationIgnored private let eventFetcher: (Date, Date) -> [EKEvent]
    @ObservationIgnored private let eventStore: EKEventStore
    @ObservationIgnored private let notificationCenter: NotificationCenter
    @ObservationIgnored private let accessStateOverride: CalendarAccessState?
    @ObservationIgnored private var storeObserver: NSObjectProtocol?
    @ObservationIgnored private var loadedDay: Date?

    init(
        eventStore: EKEventStore = EKEventStore(),
        notificationCenter: NotificationCenter = .default,
        accessStateOverride: CalendarAccessState? = nil,
        eventFetcher: ((Date, Date) -> [EKEvent])? = nil
    ) {
        self.eventStore = eventStore
        self.eventFetcher = eventFetcher ?? { start, end in
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
            return eventStore.events(matching: predicate)
        }
        self.notificationCenter = notificationCenter
        self.accessStateOverride = accessStateOverride
        accessState = accessStateOverride ?? Self.currentAccessState

        storeObserver = notificationCenter.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.authorizationDidChange()
            }
        }
    }

    deinit {
        if let storeObserver {
            notificationCenter.removeObserver(storeObserver)
        }
    }

    @discardableResult
    func requestAccess() async -> Bool {
        guard !isRequestingAccess else { return accessState.canReadEvents }

        isRequestingAccess = true
        lastError = nil
        defer { isRequestingAccess = false }

        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            accessState = resolvedAccessState
            if granted, let loadedDay {
                refresh(for: loadedDay)
            }
            return granted
        } catch {
            accessState = resolvedAccessState
            lastError = error.localizedDescription
            return false
        }
    }

    func refresh(for date: Date) {
        loadedDay = Calendar.current.startOfDay(for: date)
        accessState = resolvedAccessState

        guard accessState.canReadEvents else {
            events = []
            return
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            events = []
            return
        }

        events = eventFetcher(start, end)
            .compactMap { CalendarTimelineEvent(event: $0) }
            .sorted {
                if $0.startDate == $1.startDate { return $0.endDate < $1.endDate }
                return $0.startDate < $1.startDate
            }
    }

    func events(at date: Date) -> [CalendarTimelineEvent] {
        events.filter { $0.contains(date) }
    }

    /// Opens Calendar with the selected event visible. Calendar's event URL
    /// requires the EventKit event identifier, not ZoneBar's composite row ID.
    func openInCalendar(_ event: CalendarTimelineEvent) {
        if let eventURL = Self.calendarURL(for: event),
           NSWorkspace.shared.open(eventURL) {
            return
        }

        // Some imported or read-only events do not expose a usable identifier.
        // Opening Calendar itself is preferable to leaving the click inert.
        guard let calendarAppURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.iCal"
        ) else { return }

        NSWorkspace.shared.openApplication(
            at: calendarAppURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    nonisolated static func calendarURL(for event: CalendarTimelineEvent) -> URL? {
        guard let identifier = event.eventIdentifier?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ), !identifier.isEmpty else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "ical"
        components.host = "ekevent"
        components.path = "/\(identifier)"
        components.queryItems = [
            URLQueryItem(name: "method", value: "show"),
            URLQueryItem(name: "options", value: "more"),
        ]
        return components.url
    }

    func openPrivacySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    private func authorizationDidChange() {
        accessState = resolvedAccessState
        if let loadedDay {
            refresh(for: loadedDay)
        } else if !accessState.canReadEvents {
            events = []
        }
    }

    private static var currentAccessState: CalendarAccessState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: .notDetermined
        case .fullAccess: .connected
        case .denied: .denied
        case .restricted: .restricted
        case .writeOnly: .writeOnly
        @unknown default: .restricted
        }
    }

    private var resolvedAccessState: CalendarAccessState {
        accessStateOverride ?? Self.currentAccessState
    }
}
