import AppKit
import Foundation
import Testing
@testable import ZoneBar

@MainActor
struct TimeTickerTests {
    @MainActor
    private final class ClockHarness {
        var date = Date(timeIntervalSince1970: 1_900_000_017.75)
        var timers: [Timer] = []
        let applicationNotifications = NotificationCenter()
        let workspaceNotifications = NotificationCenter()

        func makeTicker(startsAutomatically: Bool = true) -> TimeTicker {
            TimeTicker(
                now: date,
                startsAutomatically: startsAutomatically,
                dateProvider: { self.date },
                timerFactory: { date, action in
                    let timer = Timer(fire: date, interval: 0, repeats: false) { _ in
                        MainActor.assumeIsolated { action() }
                    }
                    self.timers.append(timer)
                    return timer
                },
                notificationCenter: applicationNotifications,
                workspaceNotificationCenter: workspaceNotifications
            )
        }
    }

    @Test func nextMinuteUsesTheExactWallClockBoundary() {
        #expect(TimeTicker.nextMinute(after: Date(timeIntervalSince1970: 1_900_000_017.75))
                == Date(timeIntervalSince1970: 1_900_000_020))
        #expect(TimeTicker.nextMinute(after: Date(timeIntervalSince1970: 1_900_000_020))
                == Date(timeIntervalSince1970: 1_900_000_080))
        #expect(TimeTicker.nextMinute(after: Date(timeIntervalSince1970: -0.25))
                == Date(timeIntervalSince1970: 0))
    }

    @Test func initialTickDoesNotCarryStartupFractionalSeconds() throws {
        let clock = ClockHarness()
        let ticker = clock.makeTicker()
        let timer = try #require(clock.timers.first)
        #expect(ticker.now == clock.date)
        #expect(timer.fireDate == Date(timeIntervalSince1970: 1_900_000_020))
        #expect(timer.isValid)
    }

    @Test func delayedTickReschedulesForTheNextMinuteInsteadOfSixtySecondsLater() throws {
        let clock = ClockHarness()
        let ticker = clock.makeTicker()
        let first = try #require(clock.timers.first)
        clock.date = Date(timeIntervalSince1970: 1_900_000_037.25)
        first.fire()

        #expect(ticker.now == clock.date)
        #expect(clock.timers.count == 2)
        #expect(!first.isValid)
        #expect(clock.timers.last?.fireDate == Date(timeIntervalSince1970: 1_900_000_080))
        #expect(clock.timers.filter { $0.isValid }.count == 1)
    }

    @Test func firstTickRunsDuringMenuEventTracking() throws {
        let clock = ClockHarness()
        let ticker = clock.makeTicker()
        let first = try #require(clock.timers.first)
        clock.date = Date(timeIntervalSince1970: 1_900_000_020)
        // Bring only this test timer forward; no changes to the system clock.
        first.fireDate = Date().addingTimeInterval(0.02)
        let deadline = Date().addingTimeInterval(0.5)
        while ticker.now != clock.date && Date() < deadline {
            _ = RunLoop.main.run(mode: .eventTracking, before: deadline)
        }

        #expect(ticker.now == clock.date)
        #expect(clock.timers.count == 2)
        #expect(clock.timers.last?.fireDate == Date(timeIntervalSince1970: 1_900_000_080))
    }

    @Test(arguments: [
        NSWorkspace.didWakeNotification,
        NSWorkspace.screensDidWakeNotification,
        NSWorkspace.sessionDidBecomeActiveNotification
    ])
    func wakeAndUnlockImmediatelyRefreshAndRealign(_ name: Notification.Name) {
        let clock = ClockHarness()
        let ticker = clock.makeTicker()
        clock.date = Date(timeIntervalSince1970: 1_900_007_203.5)
        clock.workspaceNotifications.post(name: name, object: nil)

        #expect(ticker.now == clock.date)
        #expect(clock.timers.last?.fireDate == Date(timeIntervalSince1970: 1_900_007_220))
        #expect(clock.timers.filter { $0.isValid }.count == 1)
    }

    @Test(arguments: [
        NSApplication.didBecomeActiveNotification,
        Notification.Name.NSSystemClockDidChange,
        Notification.Name.NSSystemTimeZoneDidChange
    ])
    func activationAndClockChangesImmediatelyRefresh(_ name: Notification.Name) {
        let clock = ClockHarness()
        let ticker = clock.makeTicker()
        clock.date = clock.date.addingTimeInterval(-3_600)
        clock.applicationNotifications.post(name: name, object: nil)

        #expect(ticker.now == clock.date)
        #expect(clock.timers.last?.fireDate == Date(timeIntervalSince1970: 1_899_996_420))
        #expect(clock.timers.filter { $0.isValid }.count == 1)
    }

    @Test func openingPopoverCanRefreshBeforeTheTimerFires() {
        let clock = ClockHarness()
        let ticker = clock.makeTicker()
        clock.date = clock.date.addingTimeInterval(75)
        ticker.synchronize()

        #expect(ticker.now == clock.date)
        #expect(clock.timers.count == 2)
        #expect(clock.timers.filter { $0.isValid }.count == 1)
    }

    @Test func frozenPreviewsStayFrozenAcrossLifecycleChanges() {
        let clock = ClockHarness()
        let ticker = clock.makeTicker(startsAutomatically: false)
        let frozen = ticker.now
        clock.date = clock.date.addingTimeInterval(7_200)
        ticker.synchronize()
        clock.applicationNotifications.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        clock.workspaceNotifications.post(name: NSWorkspace.didWakeNotification, object: nil)

        #expect(ticker.now == frozen)
        #expect(clock.timers.isEmpty)
    }

    @Test func releasingTickerCancelsItsTimerAndObservers() {
        let clock = ClockHarness()
        var ticker: TimeTicker? = clock.makeTicker()
        weak var released = ticker
        ticker = nil

        #expect(released == nil)
        #expect(clock.timers.allSatisfy { !$0.isValid })
        clock.workspaceNotifications.post(name: NSWorkspace.didWakeNotification, object: nil)
        #expect(clock.timers.count == 1)
    }
}
