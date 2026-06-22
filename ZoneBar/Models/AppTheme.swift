import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
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
        case .spaces: return "Spaces"
        case .dot: return "Dot"
        case .pipe: return "Pipe"
        case .slash: return "Slash"
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
