import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return String(localized: "System")
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum SeparatorStyle: String, CaseIterable, Identifiable {
    case spaces
    case dot
    case pipe
    case slash

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spaces: return String(localized: "Spaces")
        case .dot: return String(localized: "Dot")
        case .pipe: return String(localized: "Pipe")
        case .slash: return String(localized: "Slash")
        }
    }

    var value: String {
        switch self {
        case .spaces: return "   "
        case .dot: return "  •  "
        case .pipe: return "  |  "
        case .slash: return "  /  "
        }
    }
}
