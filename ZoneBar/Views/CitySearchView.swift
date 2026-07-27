import SwiftUI

struct CitySearchView: View {
    @Environment(ClockStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(TimeTicker.self) private var ticker

    var autoFocus: Bool = false
    var onAdded: (() -> Void)?

    @State private var searchText = ""
    @State private var results: [CityEntry] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            field

            if !results.isEmpty {
                resultsList
            }
        }
        .onAppear { if autoFocus { isFocused = true } }
    }

    private var field: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.system(size: 12))

            TextField("Search for a city…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onChange(of: searchText) { _, newValue in performSearch(newValue) }
                .onSubmit { if let first = results.first { add(first) } }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .frame(minHeight: 36)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: DS.Radius.row, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.row, style: .continuous)
                .strokeBorder(DS.borderColor, lineWidth: 1)
        )
    }

    private var resultsList: some View {
        let shown = Array(results.prefix(7))
        return VStack(spacing: 0) {
            ForEach(shown) { city in
                resultRow(city)
                if city.id != shown.last?.id {
                    Rectangle().fill(DS.dividerColor).frame(height: 1)
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.borderColor, lineWidth: 1)
        )
    }

    private func resultRow(_ city: CityEntry) -> some View {
        Button {
            add(city)
        } label: {
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
                if store.contains(timezone: city.timezone) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                } else {
                    Text(timeFor(city))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func performSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        results = trimmed.isEmpty ? [] : CityDatabase.shared.search(query: trimmed)
    }

    private func add(_ city: CityEntry) {
        store.addClock(
            name: city.name,
            country: city.country,
            timezone: city.timezone,
            abbreviation: city.compactName
        )
        searchText = ""
        results = []
        onAdded?()
    }

    private func timeFor(_ city: CityEntry) -> String {
        guard let tz = TimeZone(identifier: city.timezone) else { return "" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = settings.is24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: ticker.now)
    }
}
