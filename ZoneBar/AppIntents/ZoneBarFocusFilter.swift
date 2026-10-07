import AppIntents
import Foundation

struct FocusClockEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Clock"
    static var defaultQuery = FocusClockQuery()

    let id: String
    let name: String
    let country: String

    init(clock: WorldClock) {
        id = clock.timezone
        name = clock.name
        country = clock.country
    }

    init(timezone: String) {
        id = timezone
        name = timezone.split(separator: "/").last.map(String.init)?
            .replacingOccurrences(of: "_", with: " ") ?? timezone
        country = ""
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(id)")
    }

    static func resolve(identifiers: [String], clocks: [WorldClock]) -> [Self] {
        identifiers.compactMap { identifier in
            if let clock = clocks.first(where: { $0.timezone == identifier }) {
                return Self(clock: clock)
            }
            // Keep a removed clock's entity resolvable so one deleted clock
            // doesn't invalidate the other clocks configured for this Focus.
            guard TimeZone(identifier: identifier) != nil else { return nil }
            return Self(timezone: identifier)
        }
    }
}

struct FocusClockQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [FocusClockEntity] {
        let clocks = await savedClocks()
        return FocusClockEntity.resolve(identifiers: identifiers, clocks: clocks)
    }

    func suggestedEntities() async throws -> [FocusClockEntity] {
        await savedClocks().map(FocusClockEntity.init(clock:))
    }

    func entities(matching string: String) async throws -> [FocusClockEntity] {
        let clocks = await savedClocks()
        return clocks.filter {
            [$0.name, $0.country, $0.timezone].contains {
                $0.localizedCaseInsensitiveContains(string)
            }
        }.map(FocusClockEntity.init(clock:))
    }

    @MainActor
    private func savedClocks() -> [WorldClock] {
        ClockStore(seedDefaults: false).clocks
    }
}

struct ZoneBarFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Choose clocks"
    static var description: IntentDescription? = "Choose which clocks ZoneBar shows while this Focus is active."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Clocks")
    var clocks: [FocusClockEntity]?

    var displayRepresentation: DisplayRepresentation {
        let names = clocks?.map(\.name).joined(separator: ", ") ?? ""
        return DisplayRepresentation(title: "Choose clocks", subtitle: "\(names)")
    }

    func perform() async throws -> some IntentResult {
        await FocusClockFilter.shared.apply(timezones: clocks?.map(\.id))
        return .result()
    }
}
