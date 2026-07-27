import Foundation
import Testing
@testable import ZoneBar

struct AppSettingsTests {
    @Test func languageDefaultsToAutomatic() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        #expect(settings.language == .automatic)
        #expect(settings.locale == .autoupdatingCurrent)
    }

    @Test func languageOverridePersists() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.language = .japanese

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.language == .japanese)
        #expect(reloaded.locale.language.languageCode?.identifier == "ja")
    }

    @Test func japaneseResourcesAreAvailable() {
        #expect(AppLanguage.japanese.localized("Settings") == "設定")
        #expect(AppLanguage.japanese.localized("Tomorrow") == "明日")
    }

    private func makeDefaults() throws -> (UserDefaults, String) {
        let suiteName = "AppSettingsTests.\(UUID().uuidString)"
        return (try #require(UserDefaults(suiteName: suiteName)), suiteName)
    }
}
