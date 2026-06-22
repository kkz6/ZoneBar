import Testing
import SwiftUI
import AppKit
@testable import ZoneBar

@MainActor
struct SnapshotTests {
    private static let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("zonebar_snapshots", isDirectory: true)

    private func snapshot(_ name: String, size: CGSize, @ViewBuilder _ content: () -> some View) {
        try? FileManager.default.createDirectory(at: Self.dir, withIntermediateDirectories: true)
        print("SNAPSHOT_DIR=\(Self.dir.path)")
        let view = content()
            .frame(width: size.width, height: size.height)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            Issue.record("Failed to render \(name)")
            return
        }
        try? png.write(to: Self.dir.appendingPathComponent("\(name).png"))
    }

    @Test func renderAllScreens() {
        let store = ClockStore()
        if store.clocks.isEmpty {
            store.addClock(name: "Tokyo", country: "JP", timezone: "Asia/Tokyo")
            store.addClock(name: "Dublin", country: "IE", timezone: "Europe/Dublin")
        }
        let settings = AppSettings()
        let ticker = TimeTicker()

        func wrap(_ view: some View) -> some View {
            view
                .environment(store)
                .environment(settings)
                .environment(ticker)
                .tint(.zoneAccent)
        }

        let detail = CGSize(width: 400, height: 520)
        snapshot("general", size: detail) { wrap(GeneralPane()).background(Color(white: 0.92)) }
        snapshot("menubar", size: detail) { wrap(MenuBarPane()).background(Color(white: 0.92)) }
        snapshot("clocks", size: detail) { wrap(ClocksPane()).background(Color(white: 0.92)) }
        snapshot("appearance", size: detail) { wrap(AppearancePane()).background(Color(white: 0.92)) }
        snapshot("about", size: detail) { wrap(AboutPane()).background(Color(white: 0.92)) }
        snapshot("settings_full", size: CGSize(width: 600, height: 460)) {
            wrap(SettingsWindow()).background(Color(white: 0.92))
        }
        snapshot("popover", size: CGSize(width: 320, height: 420)) {
            wrap(ClockPopover()).background(Color(white: 0.96))
        }
    }
}
