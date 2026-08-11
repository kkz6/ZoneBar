import Testing
import SwiftUI
import AppKit
import CryptoKit
@testable import ZoneBar

@MainActor
struct SnapshotTests {
    private static let failureDirectory = URL(
        fileURLWithPath: NSTemporaryDirectory(),
        isDirectory: true
    )
        .appendingPathComponent("zonebar_snapshots", isDirectory: true)

    // Updated only after reviewing an intentional visual change.
    private static let approvedHashes: [String: String] = [
        "general": "86a5a9eee67ed141f50d1eeac13853a099b799b440fa5a9640261f95b5671609",
        "menubar": "e05ff55a4620e178ef7c27d7f10b02f911876e47739647143fb8315f50488bae",
        "clocks": "9faf6c46eec21882079caaffe59c246ca047623570982d2edf3a621182c9899c",
        "calendar": "d81aee7ed64f665378ef33d425b8f762c2b618f6793386d3d0c01cdd8f676478",
        "appearance": "8a01341ba7ecb9d6472d6b10c443cbaf239524f12ddcbba01f3ee766d22db2f1",
        "about": "56741dab23feef86f9f978ed5638e778ff4d5c2dbfac36d8f6a2efcbc136d229",
        "settings_full": "e91f047ad9b1a7aa3a3963c1b340d48d2ec0115906ff277cc1eb4bb568f2b90d",
        "popover": "52520e4a58ec334c7ef49da0b9505f91855a9e7c9f69ccea92e7eccf2e6186f5",
    ]

    private func snapshot(
        _ name: String,
        size: CGSize,
        @ViewBuilder _ content: () -> some View
    ) throws {
        let view = content()
            .frame(width: size.width, height: size.height)
            .environment(\.colorScheme, .light)

        let hostingView = NSHostingView(rootView: AnyView(view))
        hostingView.frame = NSRect(origin: .zero, size: size)

        guard let rep = hostingView.bitmapImageRepForCachingDisplay(
            in: hostingView.bounds
        ) else {
            throw SnapshotError.renderFailed(name)
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

        guard let png = rep.representation(using: .png, properties: [:]) else {
            throw SnapshotError.renderFailed(name)
        }

        let hash = SHA256.hash(data: png)
            .map { String(format: "%02x", $0) }
            .joined()

        if Self.isRecording {
            print("SNAPSHOT_HASH \(name) \(hash)")
            return
        }

        guard let approvedHash = Self.approvedHashes[name] else {
            throw SnapshotError.missingReference(name)
        }

        guard hash == approvedHash else {
            try FileManager.default.createDirectory(
                at: Self.failureDirectory,
                withIntermediateDirectories: true
            )
            let failureURL = Self.failureDirectory
                .appendingPathComponent("\(name)-actual.png")
            try png.write(to: failureURL, options: .atomic)
            throw SnapshotError.mismatch(name: name, actualPath: failureURL.path)
        }
    }

    private static var isRecording: Bool {
#if RECORD_SNAPSHOTS
        true
#else
        false
#endif
    }

    @Test func renderAllScreens() throws {
        let store = ClockStore(
            saveURL: Self.failureDirectory.appendingPathComponent("test-clocks.json"),
            seedDefaults: false
        )
        store.clocks = [
            WorldClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo"),
            WorldClock(name: "Dublin", country: "IE", timezone: "Europe/Dublin"),
        ]
        let settings = AppSettings(
            defaults: UserDefaults(suiteName: "ZoneBar.SnapshotTests")!
        )
        let ticker = TimeTicker(
            now: Date(timeIntervalSince1970: 1_722_241_800),
            startsAutomatically: false
        )
        let updater = AppUpdater(startingUpdater: false)
        let calendarService = CalendarEventService(
            accessStateOverride: .notDetermined
        )

        func wrap(_ view: some View) -> some View {
            view
                .environment(store)
                .environment(settings)
                .environment(ticker)
                .environment(updater)
                .environment(calendarService)
                .tint(.zoneAccent)
        }

        let detail = CGSize(width: 400, height: 520)
        try snapshot("general", size: detail) {
            wrap(GeneralPane(launchAtLoginOverride: false))
                .background(Color(white: 0.92))
        }
        try snapshot("menubar", size: detail) { wrap(MenuBarPane()).background(Color(white: 0.92)) }
        try snapshot("clocks", size: detail) { wrap(ClocksPane()).background(Color(white: 0.92)) }
        try snapshot("calendar", size: detail) { wrap(CalendarPane()).background(Color(white: 0.92)) }
        try snapshot("appearance", size: detail) { wrap(AppearancePane()).background(Color(white: 0.92)) }
        try snapshot("about", size: detail) {
            wrap(AboutPane(usesApplicationIcon: false))
                .background(Color(white: 0.92))
        }
        try snapshot("settings_full", size: SettingsLayout.windowSize) {
            wrap(SettingsWindow(launchAtLoginOverride: false))
                .background(Color(white: 0.92))
        }
        try snapshot("popover", size: CGSize(width: 320, height: 420)) {
            wrap(ClockPopover()).background(Color(white: 0.96))
        }
    }
}

private enum SnapshotError: Error, CustomStringConvertible {
    case renderFailed(String)
    case missingReference(String)
    case mismatch(name: String, actualPath: String)

    var description: String {
        switch self {
        case .renderFailed(let name):
            return "Failed to render snapshot '\(name)'."
        case .missingReference(let name):
            return "Missing approved hash for '\(name)'. Run tests with RECORD_SNAPSHOTS."
        case .mismatch(let name, let actualPath):
            return "Snapshot '\(name)' changed. Actual image: \(actualPath)"
        }
    }
}
