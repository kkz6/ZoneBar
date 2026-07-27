import Testing
import CoreGraphics
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
}
