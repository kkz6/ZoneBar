import Foundation

struct WorldClock: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var country: String
    var timezone: String
    var abbreviation: String?
    var showInMenuBar: Bool
    var sortOrder: Int

    init(
        name: String,
        country: String,
        timezone: String,
        abbreviation: String? = nil,
        showInMenuBar: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.country = country
        self.timezone = timezone
        self.abbreviation = abbreviation
        self.showInMenuBar = showInMenuBar
        self.sortOrder = sortOrder
    }

    var timeZone: TimeZone? {
        TimeZone(identifier: timezone)
    }

    var compactName: String {
        abbreviation ?? CityEntry.fallbackCompactName(for: name)
    }

    func isDaytime(at now: Date) -> Bool {
        guard let tz = timeZone else { return true }
        let hour = Calendar.current.dateComponents(in: tz, from: now).hour ?? 12
        return hour >= 6 && hour < 20
    }

    func formattedTime(
        at now: Date,
        is24Hour: Bool,
        includeSeconds: Bool = false,
        locale: Locale = .current
    ) -> String {
        guard let tz = timeZone else { return "--:--" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = tz
        let template = is24Hour
            ? (includeSeconds ? "HHmmss" : "HHmm")
            : (includeSeconds ? "hmmssa" : "hmma")
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: now)
    }

    func formattedDate(at now: Date, locale: Locale = .current) -> String {
        guard let tz = timeZone else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = tz
        formatter.setLocalizedDateFormatFromTemplate("EEEddMMM")
        return formatter.string(from: now)
    }

    func relativeDayLabel(at now: Date, language: AppLanguage = .automatic) -> String? {
        guard let tz = timeZone else { return nil }
        let calendar = Calendar.current

        let targetDay = calendar.dateComponents(in: tz, from: now).day
        let localDay = calendar.dateComponents(in: calendar.timeZone, from: now).day

        guard let targetDay, let localDay else { return nil }

        let diff = targetDay - localDay
        if diff == 0 { return nil }
        if diff == 1 || diff < -25 {
            return language.localized("Tomorrow")
        }
        if diff == -1 || diff > 25 {
            return language.localized("Yesterday")
        }
        return nil
    }

    func hour(at now: Date) -> Int {
        guard let tz = timeZone else { return 12 }
        return Calendar.current.dateComponents(in: tz, from: now).hour ?? 12
    }

    func isInWorkingHours(at now: Date) -> Bool {
        let h = hour(at: now)
        return h >= 9 && h < 17
    }

    var gmtOffsetString: String {
        guard let tz = timeZone else { return "" }
        let seconds = tz.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        if minutes == 0 {
            return "GMT\(hours >= 0 ? "+" : "")\(hours)"
        }
        return "GMT\(hours >= 0 ? "+" : "")\(hours):\(String(format: "%02d", minutes))"
    }
}
