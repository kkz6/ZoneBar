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
        let contentView = try #require(window.contentView)
        let closeButton = try #require(window.standardWindowButton(.closeButton))
        let minimizeButton = try #require(window.standardWindowButton(.miniaturizeButton))
        let zoomButton = try #require(window.standardWindowButton(.zoomButton))
        let buttons = [closeButton, minimizeButton, zoomButton]
        #expect(closeButton.isEnabled)
        #expect(!minimizeButton.isEnabled)
        #expect(!zoomButton.isEnabled)
        #expect(buttons.allSatisfy { !$0.isHidden })

        let frames = try buttons.map { button -> NSRect in
            let parent = try #require(button.superview)
            // System buttons remain in the native titlebar, outside SwiftUI content.
            #expect(parent !== contentView)
            #expect(parent.bounds.contains(button.frame))
            return contentView.convert(button.frame, from: parent)
        }
        #expect(frames[0].minX == SettingsLayout.trafficLightLeading)
        for frame in frames {
            #expect(SettingsLayout.windowSize.height - frame.midY == SettingsLayout.titlebarControlCenterFromTop)
        }
        #expect(frames[1].midX - frames[0].midX == 23)
        #expect(frames[2].midX - frames[1].midX == 23)
        #expect(closeButton.frame.size == minimizeButton.frame.size)
        #expect(closeButton.frame.size == zoomButton.frame.size)

    }
}
