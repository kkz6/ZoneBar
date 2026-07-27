import SwiftUI

#if DEBUG
@MainActor
enum SettingsPreviewFixtures {
    static let store: ClockStore = {
        let store = ClockStore(
            saveURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("zonebar-preview-clocks.json"),
            seedDefaults: false
        )
        store.clocks = [
            WorldClock(
                name: "Tokyo",
                country: "JP",
                timezone: "Asia/Tokyo",
                sortOrder: 0
            ),
            WorldClock(
                name: "Dublin",
                country: "IE",
                timezone: "Europe/Dublin",
                sortOrder: 1
            ),
        ]
        return store
    }()

    static let settings = AppSettings(
        defaults: UserDefaults(suiteName: "ZoneBar.SettingsPreview")!
    )

    static let ticker = TimeTicker(
        now: Date(timeIntervalSince1970: 1_722_241_800),
        startsAutomatically: false
    )

    static let updater = AppUpdater(startingUpdater: false)
}

extension View {
    @MainActor
    func settingsPreviewEnvironment() -> some View {
        environment(SettingsPreviewFixtures.store)
            .environment(SettingsPreviewFixtures.settings)
            .environment(SettingsPreviewFixtures.ticker)
            .environment(SettingsPreviewFixtures.updater)
            .tint(.zoneAccent)
            .background(Color(nsColor: .windowBackgroundColor))
    }
}
#endif
