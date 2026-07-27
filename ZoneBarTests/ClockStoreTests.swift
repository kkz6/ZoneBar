import Foundation
import Testing
@testable import ZoneBar

struct ClockStoreTests {
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
