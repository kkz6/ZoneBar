import AppIntents
import Foundation
import Observation

/// A transient view of saved clocks. Focus never changes the saved visibility flags.
@MainActor
@Observable
final class FocusClockFilter {
    static let shared = FocusClockFilter()

    var followsFocus: Bool {
        didSet {
            defaults.set(followsFocus, forKey: "followsFocusClockFilters")
            isShowingAll = false
        }
    }
    private(set) var selectedTimezones: [String]?
    private(set) var isShowingAll = false
    private(set) var statusUnavailable = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let loadCurrent: () async throws -> [String]?
    @ObservationIgnored private var revision = 0

    init(defaults: UserDefaults = .standard, loadCurrent: (() async throws -> [String]?)? = nil) {
        self.defaults = defaults
        defaults.register(defaults: ["followsFocusClockFilters": true])
        followsFocus = defaults.bool(forKey: "followsFocusClockFilters")
        self.loadCurrent = loadCurrent ?? {
            let filter = try await ZoneBarFocusFilter.current
            return filter.clocks?.map(\.id)
        }
    }

    var hasConfiguredFilter: Bool { followsFocus && selectedTimezones != nil }
    var isFiltering: Bool { hasConfiguredFilter && !isShowingAll }

    func apply(timezones: [String]?, resetOverride: Bool = true) {
        revision += 1
        let selection = timezones.map { Array(Set($0)).sorted() }
        if resetOverride || selection != selectedTimezones { isShowingAll = false }
        selectedTimezones = selection
        statusUnavailable = false
    }

    func toggleShowAll() {
        guard hasConfiguredFilter else { return }
        isShowingAll.toggle()
    }

    func refresh() async {
        let startedAt = revision
        do {
            let selection = try await loadCurrent()
            guard startedAt == revision, !Task.isCancelled else { return }
            apply(timezones: selection, resetOverride: false)
        } catch {
            guard startedAt == revision, !Task.isCancelled else { return }
            apply(timezones: nil, resetOverride: false)
            // No configured filter is an ordinary state, not an error.
            statusUnavailable = (error as? SetFocusFilterIntentError) != .notFound
        }
    }

    func popoverClocks(from clocks: [WorldClock]) -> [WorldClock] {
        guard isFiltering, let selectedTimezones else { return clocks }
        let selected = Set(selectedTimezones)
        return clocks.filter { selected.contains($0.timezone) }
    }

    func menuBarClocks(from clocks: [WorldClock]) -> [WorldClock] {
        guard isFiltering else { return clocks.filter(\.showInMenuBar) }
        return popoverClocks(from: clocks).map { clock in
            var visibleClock = clock
            visibleClock.showInMenuBar = true
            return visibleClock
        }
    }
}
