import Foundation
import Observation

/// Owns the list of world clocks and their persistence. Pure data + CRUD —
/// no timer, no settings, no menu bar formatting.
@Observable
final class ClockStore {
    var clocks: [WorldClock] = []

    @ObservationIgnored private let saveURL: URL

    init(saveURL: URL? = nil, seedDefaults: Bool = true) {
        if let saveURL {
            self.saveURL = saveURL
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            let appDir = appSupport.appendingPathComponent("ZoneBar", isDirectory: true)
            try? FileManager.default.createDirectory(
                at: appDir,
                withIntermediateDirectories: true
            )
            self.saveURL = appDir.appendingPathComponent("clocks.json")
        }

        load()
        if clocks.isEmpty, seedDefaults {
            setupDefaults()
        }
    }

    var menuBarClocks: [WorldClock] {
        clocks.filter(\.showInMenuBar)
    }

    func contains(timezone: String) -> Bool {
        clocks.contains { $0.timezone == timezone }
    }

    func addClock(name: String, country: String, timezone: String) {
        guard !contains(timezone: timezone) else { return }
        let maxOrder = clocks.map(\.sortOrder).max() ?? -1
        clocks.append(WorldClock(
            name: name,
            country: country,
            timezone: timezone,
            showInMenuBar: true,
            sortOrder: maxOrder + 1
        ))
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

    func setMenuBarVisibility(id: UUID, visible: Bool) {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        clocks[index].showInMenuBar = visible
        save()
    }

    func renameClock(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        clocks[index].name = trimmed
        save()
    }

    // MARK: - Persistence

    private func reindex() {
        for i in clocks.indices {
            clocks[i].sortOrder = i
        }
    }

    private func setupDefaults() {
        if let local = CityDatabase.shared.detectLocalCity() {
            clocks.append(WorldClock(name: local.name, country: local.country, timezone: local.timezone, showInMenuBar: true, sortOrder: 0))
        }
        clocks.append(WorldClock(name: "UTC", country: "", timezone: "UTC", showInMenuBar: true, sortOrder: 1))
        save()
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
