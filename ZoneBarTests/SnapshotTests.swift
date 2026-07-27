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
        "general": "960e6a4de46f72e8192df5f0bb3bb3f3c5af3479fdac939e5404538d034d0b53",
        "menubar": "21e11f84e2b445e25f4cd7e1e037ec7fc19bdb120c674e0c030f2b68bb7d1732",
        "clocks": "2906cc4271e925267da2b6b0e4119d1f1c080fe46b256bda91f3db73203f46d6",
        "appearance": "96055818806854acfb8d3b695614d4113f781cc8b39a62882080089fa2022468",
        "about": "58669c31429671f83184f3af3b744e0097f00e9af384d48fb31946dbb72f61b6",
        "settings_full": "b4f8301a393736bd95bce1dac1ca40797e3b6fab64ced8fe7f809f9fa3102d07",
        "popover": "65e3851121e606d9aa5f3678466231c232bc3901de74a2f62876cc4d2040823d",
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

        func wrap(_ view: some View) -> some View {
            view
                .environment(store)
                .environment(settings)
                .environment(ticker)
                .tint(.zoneAccent)
        }

        let detail = CGSize(width: 400, height: 520)
        try snapshot("general", size: detail) { wrap(GeneralPane()).background(Color(white: 0.92)) }
        try snapshot("menubar", size: detail) { wrap(MenuBarPane()).background(Color(white: 0.92)) }
        try snapshot("clocks", size: detail) { wrap(ClocksPane()).background(Color(white: 0.92)) }
        try snapshot("appearance", size: detail) { wrap(AppearancePane()).background(Color(white: 0.92)) }
        try snapshot("about", size: detail) {
            wrap(AboutPane(usesApplicationIcon: false))
                .background(Color(white: 0.92))
        }
        try snapshot("settings_full", size: SettingsLayout.windowSize) {
            wrap(SettingsWindow()).background(Color(white: 0.92))
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
