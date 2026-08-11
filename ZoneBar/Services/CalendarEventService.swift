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

    init(
        id: String,
        eventIdentifier: String? = nil,
        title: String,
        startDate: Date,
        endDate: Date,
        calendarName: String
    ) {
        self.id = id
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarName = calendarName
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

    @ObservationIgnored private let eventStore: EKEventStore
    @ObservationIgnored private let notificationCenter: NotificationCenter
    @ObservationIgnored private let accessStateOverride: CalendarAccessState?
    @ObservationIgnored private var storeObserver: NSObjectProtocol?
    @ObservationIgnored private var loadedDay: Date?

    init(
        eventStore: EKEventStore = EKEventStore(),
        notificationCenter: NotificationCenter = .default,
        accessStateOverride: CalendarAccessState? = nil
    ) {
        self.eventStore = eventStore
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

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay && $0.status != .canceled }
            .map {
                let title = $0.title ?? ""
                let sourceID = $0.eventIdentifier ?? $0.calendarItemExternalIdentifier
                return CalendarTimelineEvent(
                    id: "\(sourceID ?? "event")-\($0.startDate.timeIntervalSinceReferenceDate)",
                    eventIdentifier: $0.eventIdentifier,
                    title: title,
                    startDate: $0.startDate,
                    endDate: $0.endDate,
                    calendarName: $0.calendar.title
                )
            }
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
