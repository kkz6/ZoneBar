import SwiftUI

struct CitySearchView: View {
    @ObservedObject var clockManager: ClockManager
    @State private var searchText = ""
    @State private var results: [CityEntry] = []
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))

                TextField("Add city...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(query: newValue)
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        results = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))

            // Search results
            if !results.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results, id: \.timezone) { city in
                            Button(action: {
                                addCity(city)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(city.name)
                                            .font(.system(size: 13, weight: .medium))
                                        if !city.country.isEmpty {
                                            Text(city.country)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(currentTimeForCity(city))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            results = []
            return
        }
        results = CityDatabase.shared.search(query: trimmed)
    }

    private func addCity(_ city: CityEntry) {
        // Don't add duplicates
        guard !clockManager.clocks.contains(where: { $0.timezone == city.timezone }) else {
            searchText = ""
            results = []
            return
        }
        clockManager.addClock(name: city.name, country: city.country, timezone: city.timezone)
        searchText = ""
        results = []
    }

    private func currentTimeForCity(_ city: CityEntry) -> String {
        guard let tz = TimeZone(identifier: city.timezone) else { return "" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = clockManager.is24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: Date())
    }
}
