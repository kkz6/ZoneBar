import EventKit
import Foundation
import Combine

final class CalendarService: ObservableObject {
    @Published var nextEvent: EKEvent?
    @Published var todayEvents: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var hasAccess: Bool = false

    private let store = EKEventStore()
    private var cancellables = Set<AnyCancellable>()

    static let shared = CalendarService()

    private init() {
        updateAuthStatus()
        observeCalendarChanges()
    }

    private func updateAuthStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        hasAccess = authorizationStatus == .fullAccess || authorizationStatus == .authorized
        if hasAccess {
            refreshEvents()
        }
    }

    func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.hasAccess = granted
                    self?.updateAuthStatus()
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.hasAccess = granted
                    self?.updateAuthStatus()
                }
            }
        }
    }

    func refreshEvents() {
        guard hasAccess else { return }

        let now = Date()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))!

        let predicate = store.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let events = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        DispatchQueue.main.async { [weak self] in
            self?.todayEvents = events
            self?.nextEvent = events.first { $0.startDate > now }
        }
    }

    func timeUntilNextEvent() -> String? {
        guard let next = nextEvent else { return nil }
        let interval = next.startDate.timeIntervalSince(Date())
        if interval < 0 { return nil }

        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainingMinutes)m"
    }

    func eventTime(event: EKEvent, in timeZone: TimeZone, is24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = is24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: event.startDate)
    }

    private func observeCalendarChanges() {
        NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: store)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshEvents()
            }
            .store(in: &cancellables)
    }
}
