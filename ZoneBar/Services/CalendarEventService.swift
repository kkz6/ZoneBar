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
    let calendarIdentifier: String
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
        calendarIdentifier: String = "",
        kind: Kind = .event,
        isAllDay: Bool = false
    ) {
        self.id = id
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarName = calendarName
        self.calendarIdentifier = calendarIdentifier
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
            calendarIdentifier: event.calendar?.calendarIdentifier ?? "",
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

enum CalendarDisplayMode: String, CaseIterable {
    case both
    case events
    case unavailable

    func includes(_ kind: CalendarTimelineEvent.Kind) -> Bool {
        switch self {
        case .both: true
        case .events: kind == .event
        case .unavailable: kind == .unavailable
        }
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
    private(set) var availableCalendars: [EKCalendar] = []
    private(set) var excludedCalendarIDs: Set<String>
    private(set) var calendarDisplayModes: [String: CalendarDisplayMode]
    private(set) var isRequestingAccess = false
    private(set) var lastError: String?

    @ObservationIgnored private let eventFetcher: ((Date, Date) -> [EKEvent])?
    @ObservationIgnored private let calendarFetcher: () -> [EKCalendar]
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let eventStore: EKEventStore
    @ObservationIgnored private let notificationCenter: NotificationCenter
    @ObservationIgnored private let accessStateOverride: CalendarAccessState?
    @ObservationIgnored private var storeObserver: NSObjectProtocol?
    @ObservationIgnored private var loadedDay: Date?

    init(
        eventStore: EKEventStore = EKEventStore(),
        notificationCenter: NotificationCenter = .default,
        accessStateOverride: CalendarAccessState? = nil,
        eventFetcher: ((Date, Date) -> [EKEvent])? = nil,
        calendarFetcher: (() -> [EKCalendar])? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.eventStore = eventStore
        self.eventFetcher = eventFetcher
        self.calendarFetcher = calendarFetcher ?? { eventStore.calendars(for: .event) }
        self.defaults = defaults
        excludedCalendarIDs = Set(defaults.stringArray(forKey: "excludedCalendarIDs") ?? [])
        calendarDisplayModes = (defaults.dictionary(forKey: "calendarDisplayModes") ?? [:])
            .reduce(into: [:]) { result, item in
                if let value = item.value as? String, let mode = CalendarDisplayMode(rawValue: value) {
                    result[item.key] = mode
                }
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
            if granted { refresh(for: loadedDay ?? Date()) }
            return granted
        } catch {
            accessState = resolvedAccessState
            lastError = error.localizedDescription
            return false
        }
    }

    func isCalendarEnabled(_ identifier: String) -> Bool {
        !excludedCalendarIDs.contains(identifier)
    }

    func displayMode(for identifier: String) -> CalendarDisplayMode {
        calendarDisplayModes[identifier] ?? .both
    }

    func setCalendarEnabled(_ identifier: String, enabled: Bool) {
        if enabled { excludedCalendarIDs.remove(identifier) }
        else { excludedCalendarIDs.insert(identifier) }
        defaults.set(excludedCalendarIDs.sorted(), forKey: "excludedCalendarIDs")
        refresh(for: loadedDay ?? Date())
    }

    func setDisplayMode(_ mode: CalendarDisplayMode, for identifier: String) {
        calendarDisplayModes[identifier] = mode
        defaults.set(calendarDisplayModes.mapValues(\.rawValue), forKey: "calendarDisplayModes")
        refresh(for: loadedDay ?? Date())
    }

    func refreshCalendars() {
        accessState = resolvedAccessState
        guard accessState.canReadEvents else {
            availableCalendars = []
            events = []
            return
        }
        availableCalendars = calendarFetcher().sorted {
            let accountOrder = ($0.source?.title ?? "").localizedStandardCompare($1.source?.title ?? "")
            if accountOrder != .orderedSame { return accountOrder == .orderedAscending }
            let titleOrder = $0.title.localizedStandardCompare($1.title)
            if titleOrder != .orderedSame { return titleOrder == .orderedAscending }
            return $0.calendarIdentifier < $1.calendarIdentifier
        }
    }

    func refresh(for date: Date) {
        loadedDay = Calendar.current.startOfDay(for: date)
        refreshCalendars()

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

        let fetchedEvents: [EKEvent]
        if let eventFetcher {
            fetchedEvents = eventFetcher(start, end)
        } else {
            let selected = availableCalendars.filter { isCalendarEnabled($0.calendarIdentifier) }
            // An empty selection must show nothing; EventKit's nil calendars
            // argument would instead fetch every calendar.
            guard !selected.isEmpty else {
                events = []
                return
            }
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: selected)
            fetchedEvents = eventStore.events(matching: predicate)
        }

        events = fetchedEvents
            .compactMap { CalendarTimelineEvent(event: $0) }
            .filter { isCalendarEnabled($0.calendarIdentifier) && displayMode(for: $0.calendarIdentifier).includes($0.kind) }
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
        } else {
            refreshCalendars()
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
