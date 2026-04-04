import Foundation
import Combine
import SwiftUI

final class ClockManager: ObservableObject {
    @Published var clocks: [WorldClock] = []
    @Published var sliderOffset: TimeInterval = 0
    @Published var isSliderActive: Bool = false

    @AppStorage("is24Hour") var is24Hour: Bool = true
    @AppStorage("showDate") var showDate: Bool = false
    @AppStorage("compactMode") var compactMode: Bool = false

    private var timer: AnyCancellable?
    private let saveURL: URL

    static let shared = ClockManager()

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("ZoneBar", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        saveURL = appDir.appendingPathComponent("clocks.json")

        load()
        if clocks.isEmpty {
            setupDefaults()
        }
        startTimer()
    }

    private func setupDefaults() {
        if let local = CityDatabase.shared.detectLocalCity() {
            clocks.append(WorldClock(
                name: local.name,
                country: local.country,
                timezone: local.timezone,
                showInMenuBar: true,
                sortOrder: 0
            ))
        }
        clocks.append(WorldClock(
            name: "UTC",
            country: "",
            timezone: "UTC",
            showInMenuBar: true,
            sortOrder: 1
        ))
        save()
    }

    private func startTimer() {
        scheduleNextMinute()
    }

    private func scheduleNextMinute() {
        let now = Date()
        let seconds = Calendar.current.component(.second, from: now)
        let delay = Double(60 - seconds)

        timer = Just(Date())
            .delay(for: .seconds(delay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.startRepeatingTimer()
            }
    }

    private func startRepeatingTimer() {
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    func addClock(name: String, country: String, timezone: String) {
        let maxOrder = clocks.map(\.sortOrder).max() ?? -1
        let clock = WorldClock(
            name: name,
            country: country,
            timezone: timezone,
            showInMenuBar: true,
            sortOrder: maxOrder + 1
        )
        clocks.append(clock)
        save()
    }

    func removeClock(id: UUID) {
        clocks.removeAll { $0.id == id }
        reindex()
        save()
    }

    func moveClock(from source: IndexSet, to destination: Int) {
        clocks.move(fromOffsets: source, toOffset: destination)
        reindex()
        save()
    }

    func toggleMenuBarVisibility(id: UUID) {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        clocks[index].showInMenuBar.toggle()
        save()
    }

    func renameClock(id: UUID, name: String) {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        clocks[index].name = name
        save()
    }

    func resetSlider() {
        sliderOffset = 0
        isSliderActive = false
    }

    var menuBarClocks: [WorldClock] {
        clocks.filter(\.showInMenuBar)
    }

    func menuBarText() -> String {
        let visible = menuBarClocks
        if visible.isEmpty { return "" }
        return visible.map { clock in
            let name = compactMode ? clock.compactName : clock.name
            let time = clock.formattedTime(offset: sliderOffset, is24Hour: is24Hour)
            return "\(name) \(time)"
        }.joined(separator: "  ")
    }

    // MARK: - Persistence

    private func reindex() {
        for i in clocks.indices {
            clocks[i].sortOrder = i
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(clocks) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([WorldClock].self, from: data) else {
            return
        }
        clocks = decoded.sorted { $0.sortOrder < $1.sortOrder }
    }
}
