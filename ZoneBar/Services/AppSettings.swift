import Foundation
import Observation

@Observable
final class AppSettings {
    var is24Hour: Bool {
        didSet { defaults.set(is24Hour, forKey: Keys.is24Hour) }
    }

    var showDate: Bool {
        didSet { defaults.set(showDate, forKey: Keys.showDate) }
    }

    var compactMode: Bool {
        didSet { defaults.set(compactMode, forKey: Keys.compactMode) }
    }

    var showDayNightIcon: Bool {
        didSet { defaults.set(showDayNightIcon, forKey: Keys.showDayNightIcon) }
    }

    var separatorStyle: SeparatorStyle {
        didSet { defaults.set(separatorStyle.rawValue, forKey: Keys.separatorStyle) }
    }

    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.is24Hour: true,
            Keys.showDate: false,
            Keys.compactMode: false,
            Keys.showDayNightIcon: false,
            Keys.separatorStyle: SeparatorStyle.spaces.rawValue,
            Keys.theme: AppTheme.system.rawValue,
        ])

        is24Hour = defaults.bool(forKey: Keys.is24Hour)
        showDate = defaults.bool(forKey: Keys.showDate)
        compactMode = defaults.bool(forKey: Keys.compactMode)
        showDayNightIcon = defaults.bool(forKey: Keys.showDayNightIcon)
        separatorStyle = SeparatorStyle(rawValue: defaults.string(forKey: Keys.separatorStyle) ?? "") ?? .spaces
        theme = AppTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .system
    }

    private enum Keys {
        static let is24Hour = "is24Hour"
        static let showDate = "showDate"
        static let compactMode = "compactMode"
        static let showDayNightIcon = "showDayNightIcon"
        static let separatorStyle = "separatorStyle"
        static let theme = "appearanceMode"
    }
}
