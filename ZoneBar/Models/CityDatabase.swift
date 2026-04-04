import Foundation

struct CityEntry: Codable, Identifiable {
    var id: String { "\(name)-\(timezone)" }
    let name: String
    let country: String
    let timezone: String
    let population: Int
    let aliases: [String]
}

final class CityDatabase {
    static let shared = CityDatabase()

    private var cities: [CityEntry] = []

    private init() {
        loadCities()
    }

    private func loadCities() {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([CityEntry].self, from: data) else {
            cities = []
            return
        }
        cities = decoded.sorted { $0.population > $1.population }
    }

    func search(query: String) -> [CityEntry] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()

        var results = cities.filter { city in
            city.name.lowercased().contains(lowered) ||
            city.aliases.contains(where: { $0.lowercased().contains(lowered) }) ||
            city.country.lowercased().contains(lowered)
        }

        // Also search Apple timezone identifiers for cities not in our database
        let appleMatches = TimeZone.knownTimeZoneIdentifiers.filter { identifier in
            let cityName = identifier.split(separator: "/").last?
                .replacingOccurrences(of: "_", with: " ") ?? ""
            return cityName.lowercased().contains(lowered)
        }

        for identifier in appleMatches {
            let alreadyExists = results.contains { $0.timezone == identifier }
            if !alreadyExists {
                let cityName = identifier.split(separator: "/").last?
                    .replacingOccurrences(of: "_", with: " ") ?? identifier
                let region = identifier.split(separator: "/").first.map(String.init) ?? ""
                results.append(CityEntry(
                    name: cityName,
                    country: region,
                    timezone: identifier,
                    population: 0,
                    aliases: []
                ))
            }
        }

        var seen = Set<String>()
        let unique = results.filter { seen.insert($0.timezone).inserted }
        return Array(unique.prefix(10))
    }

    func detectLocalCity() -> CityEntry? {
        let localIdentifier = TimeZone.current.identifier
        if let match = cities.first(where: { $0.timezone == localIdentifier }) {
            return match
        }
        let cityName = localIdentifier.split(separator: "/").last?
            .replacingOccurrences(of: "_", with: " ") ?? "Local"
        return CityEntry(
            name: cityName,
            country: "",
            timezone: localIdentifier,
            population: 0,
            aliases: []
        )
    }
}
