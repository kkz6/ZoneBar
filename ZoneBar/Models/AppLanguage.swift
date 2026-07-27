import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case automatic
    case english
    case japanese

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .automatic: return .autoupdatingCurrent
        case .english: return Locale(identifier: "en")
        case .japanese: return Locale(identifier: "ja")
        }
    }

    func localized(_ key: String) -> String {
        resourceBundle.localizedString(forKey: key, value: key, table: nil)
    }

    private var resourceBundle: Bundle {
        let localization: String?
        switch self {
        case .automatic: localization = Bundle.main.preferredLocalizations.first
        case .english: localization = "en"
        case .japanese: localization = "ja"
        }

        guard let localization,
              let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
