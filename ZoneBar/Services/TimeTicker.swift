import AppKit
import Foundation
import Observation

/// Keeps every clock on the current wall-clock minute. Each tick is scheduled
/// afresh so a delayed callback, sleep, or a clock correction cannot cause drift.
@MainActor
@Observable
final class TimeTicker {
    typealias TimerFactory = (Date, @escaping @MainActor () -> Void) -> Timer

    private(set) var now: Date

    @ObservationIgnored private let automaticallyUpdates: Bool
    @ObservationIgnored private let dateProvider: () -> Date
    @ObservationIgnored private let timerFactory: TimerFactory
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(
        now: Date = Date(),
        startsAutomatically: Bool = true,
        dateProvider: @escaping () -> Date = Date.init,
        timerFactory: @escaping TimerFactory = { date, action in
            Timer(fire: date, interval: 0, repeats: false) { _ in
                MainActor.assumeIsolated { action() }
            }
        },
        notificationCenter: NotificationCenter = .default,
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter
    ) {
        self.now = now
        automaticallyUpdates = startsAutomatically
        self.dateProvider = dateProvider
        self.timerFactory = timerFactory

        if startsAutomatically {
            observe([
                NSApplication.didBecomeActiveNotification,
                .NSSystemClockDidChange,
                .NSSystemTimeZoneDidChange
            ], on: notificationCenter)
            observe([
                NSWorkspace.didWakeNotification,
                NSWorkspace.screensDidWakeNotification,
                NSWorkspace.sessionDidBecomeActiveNotification
            ], on: workspaceNotificationCenter)
            synchronize()
        }
    }

    deinit {
        timer?.invalidate()
        for (center, token) in observers { center.removeObserver(token) }
    }

    /// Also called when the popover opens. Frozen previews do not start ticking.
    func synchronize() {
        guard automaticallyUpdates else { return }
        let current = dateProvider()
        now = current
        timer?.invalidate()
        let next = timerFactory(Self.nextMinute(after: current)) { [weak self] in
            self?.synchronize()
        }
        next.tolerance = 0.05
        timer = next
        // Applies to the very first tick too, including menu/event tracking.
        RunLoop.main.add(next, forMode: .common)
    }

    static func nextMinute(after date: Date) -> Date {
        Date(timeIntervalSince1970: (floor(date.timeIntervalSince1970 / 60) + 1) * 60)
    }

    private func observe(_ names: [Notification.Name], on center: NotificationCenter) {
        for name in names {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.synchronize() }
            }
            observers.append((center, token))
        }
    }
}
