import Foundation
import Testing
@testable import ZoneBar

struct ClockStoreTests {
    @Test func reorderingUpdatesAllClocksMenuBarAndPersistence() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let saveURL = directory.appendingPathComponent("clocks.json")
        let store = ClockStore(saveURL: saveURL, seedDefaults: false)
        store.addClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo", abbreviation: "TKY")
        store.addClock(name: "Dublin", country: "IE", timezone: "Europe/Dublin", abbreviation: "DUB")
        store.addClock(name: "UTC", country: "", timezone: "UTC", abbreviation: "UTC")
        let tokyo = store.clocks[0].id
        let dublin = store.clocks[1].id
        let utc = store.clocks[2].id
        store.setMenuBarVisibility(id: dublin, visible: false)

        // Accessibility actions and drag targets use the same persisted order.
        store.moveClock(id: utc, by: -1)
        #expect(store.clocks.map(\.id) == [tokyo, utc, dublin])
        #expect(store.moveClock(id: tokyo, onto: dublin))
        #expect(store.clocks.map(\.id) == [utc, dublin, tokyo])
        #expect(store.moveClock(id: tokyo, onto: utc))
        store.moveClock(id: tokyo, by: 1)
        #expect(store.clocks.map(\.id) == [utc, tokyo, dublin])
        #expect(store.clocks.map(\.sortOrder) == [0, 1, 2])
        #expect(store.menuBarClocks.map(\.id) == [utc, tokyo])

        let rendered = MenuBarRenderer.text(
            for: store.clocks, at: Date(timeIntervalSince1970: 0),
            is24Hour: true, compact: false, showDate: false,
            showDayNightIcon: false, separator: .pipe, locale: Locale(identifier: "en")
        )
        #expect(rendered.hasPrefix("UTC "))
        #expect(!rendered.contains("Dublin"))

        let reloadedStore = ClockStore(saveURL: saveURL, seedDefaults: false)
        #expect(reloadedStore.clocks == store.clocks)
        #expect(reloadedStore.menuBarClocks.map(\.id) == [utc, tokyo])
    }

    @Test func reorderIgnoresBoundariesAndUnknownClocks() throws {
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: saveURL) }
        let store = ClockStore(saveURL: saveURL, seedDefaults: false)
        store.addClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo")
        store.addClock(name: "UTC", country: "", timezone: "UTC")
        let original = store.clocks
        store.moveClock(id: original[0].id, by: -1)
        store.moveClock(id: original[1].id, by: 1)
        store.moveClock(id: UUID(), by: 1)
        #expect(!store.moveClock(id: original[0].id, onto: original[0].id))
        #expect(!store.moveClock(id: UUID(), onto: original[0].id))
        #expect(!store.moveClock(id: original[0].id, onto: UUID()))
        #expect(store.clocks == original)
    }

    @Test func menuBarVisibilityUpdatesCurrentValueAndPersists() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let saveURL = directory.appendingPathComponent("clocks.json")
        let store = ClockStore(saveURL: saveURL, seedDefaults: false)
        store.addClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo")

        let id = try #require(store.clocks.first?.id)
        store.setMenuBarVisibility(id: id, visible: false)

        #expect(store.clocks.first?.showInMenuBar == false)
        #expect(store.menuBarClocks.isEmpty)

        let reloadedStore = ClockStore(saveURL: saveURL, seedDefaults: false)
        #expect(reloadedStore.clocks.first?.showInMenuBar == false)
        #expect(reloadedStore.menuBarClocks.isEmpty)
    }

    @Test func visibilityUpdateForUnknownClockDoesNothing() {
        let store = ClockStore(
            saveURL: FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString),
            seedDefaults: false
        )

        store.setMenuBarVisibility(id: UUID(), visible: false)

        #expect(store.clocks.isEmpty)
    }
}
