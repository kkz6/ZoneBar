import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, SettingsDestination {
    case general
    case menuBar
    case clocks
    case calendar
    case appearance
    case about

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .general: return "General"
        case .menuBar: return "Menu Bar"
        case .clocks: return "Clocks"
        case .calendar: return "Calendar"
        case .appearance: return "Appearance"
        case .about: return "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape.fill"
        case .menuBar: return "menubar.rectangle"
        case .clocks: return "clock.fill"
        case .calendar: return "calendar"
        case .appearance: return "paintbrush.fill"
        case .about: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return .gray
        case .menuBar: return .blue
        case .clocks: return .orange
        case .calendar: return .blue
        case .appearance: return .purple
        case .about: return .teal
        }
    }
}

struct SettingsWindow: View {
    static let windowID = "settings"

    @State private var selection: SettingsSection = .general
    private let launchAtLoginOverride: Bool?

    init(launchAtLoginOverride: Bool? = nil) {
        self.launchAtLoginOverride = launchAtLoginOverride
    }

    private let groups: [SettingsSidebarGroup<SettingsSection>] = [
        .init("general", destinations: [.general]),
        .init("clocks", header: "Clocks", destinations: [.clocks, .menuBar]),
        .init("integrations", header: "Integrations", destinations: [.calendar]),
        .init("app", header: "App", destinations: [.appearance, .about]),
    ]

    var body: some View {
        SettingsShell(selection: $selection, groups: groups) { section in
            detail(for: section)
        }
    }

    @ViewBuilder
    private func detail(for section: SettingsSection) -> some View {
        switch section {
        case .general: GeneralPane(launchAtLoginOverride: launchAtLoginOverride)
        case .menuBar: MenuBarPane()
        case .clocks: ClocksPane()
        case .calendar: CalendarPane()
        case .appearance: AppearancePane()
        case .about: AboutPane()
        }
    }
}

// MARK: - Pane scaffold

/// Shared layout for a settings detail pane: a large titled header followed by a
/// scrollable stack of grouped card sections.
struct SettingsPane<Destination: SettingsDestination, Content: View>: View {
    let section: Destination
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.detailSectionSpacing) {
            HStack(spacing: DS.Spacing.sm) {
                IconTile(symbol: section.symbol, color: section.color, size: 22)
                Text(section.title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(height: SettingsLayout.detailHeaderHeight)

            content
        }
        .padding(.horizontal, SettingsLayout.detailHorizontalInset)
        .padding(.top, SettingsLayout.detailTopInset)
        .padding(.bottom, SettingsLayout.detailBottomInset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A labelled group: an optional section header above a SettingsCard.
struct SettingsGroup<Content: View>: View {
    var header: LocalizedStringKey?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.groupHeaderSpacing) {
            if let header {
                SectionHeader(title: header)
            }
            SettingsCard {
                content
            }
        }
    }
}

#if DEBUG
#Preview("Settings Window") {
    SettingsWindow(launchAtLoginOverride: false)
        .settingsPreviewEnvironment()
        .frame(
            width: SettingsLayout.windowSize.width,
            height: SettingsLayout.windowSize.height
        )
}
#endif
