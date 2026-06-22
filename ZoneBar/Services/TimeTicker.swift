import Foundation
import Combine
import Observation

/// Publishes the current time, aligned to minute boundaries so the displayed
/// clocks never drift. Views observe `now` and re-render when it changes.
@Observable
final class TimeTicker {
    private(set) var now: Date = Date()

    @ObservationIgnored private var timer: AnyCancellable?

    init() {
        scheduleNextMinute()
    }

    private func scheduleNextMinute() {
        let seconds = Calendar.current.component(.second, from: Date())
        let delay = Double(60 - seconds)

        timer = Just(())
            .delay(for: .seconds(delay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.now = Date()
                self?.startRepeating()
            }
    }

    private func startRepeating() {
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.now = Date()
            }
    }
}
