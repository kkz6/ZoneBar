import AppIntents
import Foundation
import Testing
@testable import ZoneBar

@MainActor
struct FocusClockFilterTests {
    private func withFilter(
        loader: @escaping () async throws -> [String]? = { nil },
        _ body: (FocusClockFilter, UserDefaults) async throws -> Void
    ) async throws {
        let suite = "ZoneBar.FocusTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let filter = FocusClockFilter(defaults: defaults, loadCurrent: loader)
        try await body(filter, defaults)
    }

    private var clocks: [WorldClock] {
        [
            WorldClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo", showInMenuBar: true),
            WorldClock(name: "Dublin", country: "IE", timezone: "Europe/Dublin", showInMenuBar: false),
            WorldClock(name: "UTC", country: "", timezone: "UTC", showInMenuBar: true)
        ]
    }

    @Test func focusSelectionOverridesVisibilityWithoutChangingSavedClocks() async throws {
        try await withFilter { filter, _ in
            let saved = clocks
            filter.apply(timezones: ["Europe/Dublin", "Asia/Tokyo"])
            #expect(filter.isFiltering)
            #expect(filter.popoverClocks(from: saved).map(\.name) == ["Tokyo", "Dublin"])
            #expect(filter.menuBarClocks(from: saved).map(\.name) == ["Tokyo", "Dublin"])
            #expect(filter.menuBarClocks(from: saved).allSatisfy { $0.showInMenuBar })
            #expect(saved.map(\.showInMenuBar) == [true, false, true])
            #expect(saved[1].showInMenuBar == false)

            filter.apply(timezones: nil)
            #expect(!filter.isFiltering)
            #expect(filter.popoverClocks(from: saved) == saved)
            #expect(filter.menuBarClocks(from: saved).map(\.name) == ["Tokyo", "UTC"])
        }
    }

    @Test func showAllIsTemporaryAndResumesWithoutEditingVisibility() async throws {
        try await withFilter { filter, _ in
            filter.apply(timezones: ["Europe/Dublin"])
            filter.toggleShowAll()
            #expect(filter.isShowingAll)
            #expect(filter.popoverClocks(from: clocks).count == 3)
            #expect(filter.menuBarClocks(from: clocks).map(\.name) == ["Tokyo", "UTC"])
            filter.toggleShowAll()
            #expect(filter.popoverClocks(from: clocks).map(\.name) == ["Dublin"])

            filter.toggleShowAll()
            filter.apply(timezones: ["UTC"])
            #expect(!filter.isShowingAll)
            #expect(filter.popoverClocks(from: clocks).map(\.name) == ["UTC"])
        }
    }

    @Test func disabledPreferencePersistsAndUsesNormalSelection() async throws {
        try await withFilter { filter, defaults in
            filter.apply(timezones: ["Europe/Dublin"])
            filter.followsFocus = false
            #expect(!filter.hasConfiguredFilter)
            #expect(filter.menuBarClocks(from: clocks).map(\.name) == ["Tokyo", "UTC"])
            #expect(!FocusClockFilter(defaults: defaults, loadCurrent: { nil }).followsFocus)
            filter.followsFocus = true
            #expect(filter.popoverClocks(from: clocks).map(\.name) == ["Dublin"])
        }
    }

    @Test func unchangedRefreshKeepsOverrideButNewTransitionResetsIt() async throws {
        try await withFilter(loader: { ["UTC"] }) { filter, _ in
            filter.apply(timezones: ["UTC"])
            filter.toggleShowAll()
            await filter.refresh()
            #expect(filter.isShowingAll)
            filter.apply(timezones: ["UTC"])
            #expect(!filter.isShowingAll)
        }
    }

    @Test func startupAndFocusEndReadCurrentSystemConfiguration() async throws {
        try await withFilter(loader: { ["Europe/Dublin"] }) { filter, _ in
            await filter.refresh()
            #expect(filter.popoverClocks(from: clocks).map(\.name) == ["Dublin"])
        }
        try await withFilter { filter, _ in
            filter.apply(timezones: ["Europe/Dublin"])
            await filter.refresh()
            #expect(!filter.hasConfiguredFilter)
            #expect(filter.menuBarClocks(from: clocks).map(\.name) == ["Tokyo", "UTC"])
        }
    }

    @Test func missingFilterRestoresNormalSelectionWithoutAnError() async throws {
        try await withFilter(loader: { throw SetFocusFilterIntentError.notFound }) { filter, _ in
            filter.apply(timezones: ["UTC"])
            await filter.refresh()
            #expect(!filter.hasConfiguredFilter)
            #expect(!filter.statusUnavailable)
        }
    }

    @Test func unavailableStatusFallsBackToUsualClocks() async throws {
        try await withFilter(loader: { throw CocoaError(.fileReadUnknown) }) { filter, _ in
            filter.apply(timezones: ["Europe/Dublin"])
            await filter.refresh()
            #expect(filter.statusUnavailable)
            #expect(filter.menuBarClocks(from: clocks).map(\.name) == ["Tokyo", "UTC"])
        }
    }

    @Test func emptyAndDeletedSelectionsDoNotLeakOtherClocks() async throws {
        try await withFilter { filter, _ in
            filter.apply(timezones: [])
            #expect(filter.isFiltering)
            #expect(filter.popoverClocks(from: clocks).isEmpty)
            filter.apply(timezones: ["Asia/Tokyo", "Asia/Tokyo", "America/New_York"])
            #expect(filter.selectedTimezones?.count == 2)
            #expect(filter.popoverClocks(from: clocks).map(\.name) == ["Tokyo"])
            filter.toggleShowAll()
            #expect(filter.popoverClocks(from: clocks).count == 3)
        }
    }

    @Test func staleRefreshCannotOverwriteANewerFocusTransition() async throws {
        var continuation: CheckedContinuation<[String]?, Error>?
        try await withFilter(loader: {
            try await withCheckedThrowingContinuation { continuation = $0 }
        }) { filter, _ in
            let refresh = Task { await filter.refresh() }
            while continuation == nil { await Task.yield() }
            filter.apply(timezones: ["Europe/Dublin"])
            continuation?.resume(returning: ["UTC"])
            await refresh.value
            #expect(filter.popoverClocks(from: clocks).map(\.name) == ["Dublin"])
        }
    }

    @Test func entitiesUseStableTimezonesAndResolveRemovedClocks() {
        let original = clocks[0]
        var renamed = original
        renamed.name = "Japan team"
        let resolved = FocusClockEntity.resolve(
            identifiers: ["Asia/Tokyo", "America/New_York", "not-a-timezone"], clocks: [renamed]
        )
        #expect(FocusClockEntity(clock: original).id == FocusClockEntity(clock: renamed).id)
        #expect(resolved.map(\.id) == ["Asia/Tokyo", "America/New_York"])
        #expect(resolved.map(\.name) == ["Japan team", "New York"])
        #expect(ZoneBarFocusFilter().clocks == nil)
    }
}
