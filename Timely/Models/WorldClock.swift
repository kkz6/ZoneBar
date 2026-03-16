import Foundation

struct WorldClock: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var country: String
    var timezone: String
    var showInMenuBar: Bool
    var sortOrder: Int

    init(name: String, country: String, timezone: String, showInMenuBar: Bool = true, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.country = country
        self.timezone = timezone
        self.showInMenuBar = showInMenuBar
        self.sortOrder = sortOrder
    }

    var timeZone: TimeZone? {
        TimeZone(identifier: timezone)
    }

    var isDaytime: Bool {
        guard let tz = timeZone else { return true }
        let hour = Calendar.current.dateComponents(in: tz, from: Date()).hour ?? 12
        return hour >= 4 && hour <= 21
    }

    var compactName: String {
        let words = name.split(separator: " ")
        if words.count > 1 {
            return words.map { String($0.prefix(1)) }.joined().uppercased()
        }
        return String(name.prefix(3)).uppercased()
    }

    func formattedTime(offset: TimeInterval = 0, is24Hour: Bool = true) -> String {
        guard let tz = timeZone else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = is24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: Date().addingTimeInterval(offset))
    }

    func formattedDate(offset: TimeInterval = 0) -> String {
        guard let tz = timeZone else { return "" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "EEE, dd MMM"
        return formatter.string(from: Date().addingTimeInterval(offset))
    }

    func relativeDayLabel(offset: TimeInterval = 0) -> String? {
        guard let tz = timeZone else { return nil }
        let now = Date().addingTimeInterval(offset)
        let localCalendar = Calendar.current
        let targetComponents = localCalendar.dateComponents(in: tz, from: now)
        let localComponents = localCalendar.dateComponents(in: localCalendar.timeZone, from: now)

        guard let targetDay = targetComponents.day, let localDay = localComponents.day else { return nil }

        let diff = targetDay - localDay
        if diff == 0 { return nil }
        if diff == 1 || diff < -25 { return "Tomorrow" }
        if diff == -1 || diff > 25 { return "Yesterday" }
        return nil
    }

    func currentHour(offset: TimeInterval = 0) -> Int {
        guard let tz = timeZone else { return 12 }
        return Calendar.current.dateComponents(in: tz, from: Date().addingTimeInterval(offset)).hour ?? 12
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
