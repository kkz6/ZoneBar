import Foundation
import Testing
@testable import ZoneBar

struct ClockDragSessionTests {
    @Test func draggingMovesWholeRowAndMakesSpaceBeforeSaving() throws {
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: saveURL) }
        let store = ClockStore(saveURL: saveURL, seedDefaults: false)
        store.addClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo")
        store.addClock(name: "Dublin", country: "IE", timezone: "Europe/Dublin")
        store.addClock(name: "UTC", country: "", timezone: "UTC")
        let original = store.clocks.map(\.id)
        let session = ClockDragSession()

        session.update(id: original[0], translation: 70, rowStride: 47, store: store)
        #expect(session.offset(id: original[0], store: store) == 70)
        #expect(session.offset(id: original[1], store: store) == -47)
        #expect(session.offset(id: original[2], store: store) == 0)
        #expect(store.clocks.map(\.id) == original)

        session.update(id: original[0], translation: 80, rowStride: 47, store: store)
        #expect(session.offset(id: original[2], store: store) == -47)
        session.settle()
        #expect(session.translation == 94)
        session.commit(store: store)
        #expect(store.clocks.map(\.id) == [original[1], original[2], original[0]])
        #expect(session.draggedID == nil)
        #expect(session.offset(id: original[0], store: store) == 0)
        #expect(ClockStore(saveURL: saveURL, seedDefaults: false).clocks.map(\.id) == store.clocks.map(\.id))
    }

    @Test func draggingUpClampsToListAndCancelKeepsOrder() {
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: saveURL) }
        let store = ClockStore(saveURL: saveURL, seedDefaults: false)
        store.addClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo")
        store.addClock(name: "UTC", country: "", timezone: "UTC")
        let original = store.clocks.map(\.id)
        let session = ClockDragSession()

        session.update(id: original[1], translation: -500, rowStride: 47, store: store)
        #expect(session.translation == -47)
        #expect(session.targetIndex == 0)
        #expect(session.offset(id: original[0], store: store) == 47)
        session.finish()
        #expect(store.clocks.map(\.id) == original)
        #expect(session.offset(id: original[0], store: store) == 0)

        session.update(id: original[0], translation: -500, rowStride: 47, store: store)
        #expect(session.translation == 0)
        session.update(id: original[0], translation: 500, rowStride: 47, store: store)
        #expect(session.translation == 47)
        session.settle()
        session.commit(store: store)
        #expect(store.clocks.map(\.id) == original.reversed().map { $0 })
    }

    @Test func shortDragSnapsBackWithoutReordering() {
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: saveURL) }
        let store = ClockStore(saveURL: saveURL, seedDefaults: false)
        store.addClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo")
        store.addClock(name: "UTC", country: "", timezone: "UTC")
        let original = store.clocks.map(\.id)
        let session = ClockDragSession()

        session.update(id: original[0], translation: 20, rowStride: 47, store: store)
        #expect(session.targetIndex == 0)
        #expect(session.offset(id: original[1], store: store) == 0)
        session.settle()
        #expect(session.translation == 0)
        session.commit(store: store)
        #expect(store.clocks.map(\.id) == original)
    }
    @Test func filteredDragUsesVisibleRowsAndPreservesHiddenClockOrder() {
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: saveURL) }
        let store = ClockStore(saveURL: saveURL, seedDefaults: false)
        store.addClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo")
        store.addClock(name: "Dublin", country: "IE", timezone: "Europe/Dublin")
        store.addClock(name: "Sydney", country: "AU", timezone: "Australia/Sydney")
        store.addClock(name: "UTC", country: "", timezone: "UTC")
        let visible = [store.clocks[0], store.clocks[3]]
        let session = ClockDragSession()

        session.update(id: visible[0].id, translation: 500, rowStride: 47,
                       store: store, displayedClocks: visible)
        #expect(session.translation == 47)
        #expect(session.targetIndex == 1)
        #expect(session.offset(id: visible[1].id, store: store) == -47)
        #expect(session.offset(id: store.clocks[1].id, store: store) == 0)
        #expect(session.offset(id: store.clocks[2].id, store: store) == 0)
        session.settle()
        session.commit(store: store)
        #expect(store.clocks.map(\.name) == ["Dublin", "Sydney", "UTC", "Tokyo"])
        #expect(ClockStore(saveURL: saveURL, seedDefaults: false).clocks.map(\.id) == store.clocks.map(\.id))
    }

}
