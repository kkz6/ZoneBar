import AppKit
import CoreGraphics
import SwiftUI
import Testing
@testable import ZoneBar

struct SettingsLayoutTests {
    @Test func titlebarAndContentShareOneGrid() {
        #expect(
            SettingsLayout.trafficLightLeading
                == SettingsLayout.sidebarOuterInset
                + SettingsLayout.sidebarRowInnerInset
        )
        #expect(
            SettingsLayout.titlebarControlCenterFromTop
                == SettingsLayout.detailTopInset
                + SettingsLayout.detailHeaderHeight / 2
        )
    }

    @Test func firstSidebarRowClearsTitlebarControls() {
        let standardTrafficLightRadius: CGFloat = 7
        let titlebarControlBottom =
            SettingsLayout.titlebarControlCenterFromTop + standardTrafficLightRadius

        #expect(SettingsLayout.sidebarFirstRowTop > titlebarControlBottom)
    }

    @Test func detailGuttersAreSymmetric() {
        let detailWidth =
            SettingsLayout.windowSize.width
            - SettingsLayout.sidebarWidth
            - 1 // Divider
        let contentWidth =
            detailWidth - 2 * SettingsLayout.detailHorizontalInset

        #expect(contentWidth > 0)
        #expect(SettingsLayout.detailHorizontalInset == 16)
    }

    @Test func shellMatchesCompactMacOSTitlebarRhythm() {
        #expect(SettingsLayout.sidebarOuterInset == 12)
        #expect(SettingsLayout.trafficLightLeading == 20)
        #expect(SettingsLayout.titlebarControlCenterFromTop == 26)
        #expect(SettingsLayout.detailSectionSpacing == 14)
    }

    @Test func cardsUseOneCompactInternalGrid() {
        #expect(SettingsLayout.groupHeaderSpacing == 6)
        #expect(SettingsLayout.cardHorizontalInset == 12)
        #expect(SettingsLayout.cardVerticalInset == 10)
        #expect(DS.Size.rowHeight == 46)
        #expect(
            SettingsLayout.cardHorizontalInset
                < SettingsLayout.detailHorizontalInset
        )
    }

    @Test func surfacesUseOneSoftCornerScale() {
        #expect(DS.Radius.card == 17)
        #expect(DS.Radius.row == 13)
        #expect(DS.Radius.control == 13)
        #expect(DS.Radius.selection == 11)
    }

    @MainActor
    @Test func windowChromeUsesFixedFrameAndEvenTrafficLightSpacing() throws {
        let controller = SettingsWindowController(
            configuration: SettingsWindowConfiguration(
                identifier: NSUserInterfaceItemIdentifier("SettingsTestWindow"),
                title: "Settings",
                size: SettingsLayout.windowSize,
                trafficLightLeading: SettingsLayout.trafficLightLeading,
                trafficLightCenterFromTop: SettingsLayout.titlebarControlCenterFromTop
            )
        )
        let window = controller.prepareWindow(
            Color.clear.frame(
                width: SettingsLayout.windowSize.width,
                height: SettingsLayout.windowSize.height
            )
        )
        defer { controller.close() }

        #expect(window.frame.size == SettingsLayout.windowSize)
        #expect(window.contentView?.frame.size == SettingsLayout.windowSize)
        #expect(window.minSize == SettingsLayout.windowSize)
        #expect(window.maxSize == SettingsLayout.windowSize)
        #expect(!window.styleMask.contains(.resizable))
        #expect(!window.styleMask.contains(.miniaturizable))
        #expect(window.standardWindowButton(.closeButton)?.isHidden == true)
        #expect(window.standardWindowButton(.miniaturizeButton)?.isHidden == true)
        #expect(window.standardWindowButton(.zoomButton)?.isHidden == true)

        let contentView = try #require(window.contentView)
        let group = try #require(contentView.subviews.first {
            $0.identifier == .settingsTrafficLightGroup
        })
        let closeButton = try #require(group.subviews.first {
            $0.identifier == .settingsCloseTrafficLight
        })
        let indicators = group.subviews
            .filter { $0.identifier == .settingsDisabledTrafficLight }
            .sorted { $0.frame.minX < $1.frame.minX }

        #expect(indicators.count == 2)
        #expect(group.frame.minX == SettingsLayout.trafficLightLeading)
        #expect(
            SettingsLayout.windowSize.height - group.frame.midY
                == SettingsLayout.titlebarControlCenterFromTop
        )
        let centerSpacing: CGFloat = 23
        let closeCenter = closeButton.frame.midX
        #expect(closeButton.frame.size == CGSize(width: 14, height: 14))
        #expect(indicators[0].frame.size == closeButton.frame.size)
        #expect(indicators[0].layer?.cornerRadius == closeButton.layer?.cornerRadius)
        #expect(indicators[0].layer?.borderWidth == closeButton.layer?.borderWidth)
        #expect(indicators[0].frame.midX - closeCenter == centerSpacing)
        #expect(indicators[1].frame.midX - indicators[0].frame.midX == centerSpacing)
    }
}
