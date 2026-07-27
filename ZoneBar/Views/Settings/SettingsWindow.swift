import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, SettingsDestination {
    case general
    case menuBar
    case clocks
    case appearance
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .menuBar: return "Menu Bar"
        case .clocks: return "Clocks"
        case .appearance: return "Appearance"
        case .about: return "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape.fill"
        case .menuBar: return "menubar.rectangle"
        case .clocks: return "clock.fill"
        case .appearance: return "paintbrush.fill"
        case .about: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return .gray
        case .menuBar: return .blue
        case .clocks: return .orange
        case .appearance: return .purple
        case .about: return .teal
        }
    }
}

struct SettingsWindow: View {
    static let windowID = "settings"

    @State private var selection: SettingsSection = .general

    private let groups: [SettingsSidebarGroup<SettingsSection>] = [
        .init("general", destinations: [.general]),
        .init("clocks", header: "Clocks", destinations: [.clocks, .menuBar]),
        .init("app", header: "App", destinations: [.appearance, .about]),
    ]

    var body: some View {
        SettingsShell(selection: $selection, groups: groups) { section in
            detail(for: section)
        }
        .onAppear {
            // The app remains an accessory app so MenuBarExtra keeps its native
            // panel styling. Activate only after SwiftUI has created the
            // settings window, allowing it to become key without changing the
            // process-wide activation policy.
            DispatchQueue.main.async {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.windows
                    .first(where: {
                        $0.identifier?.rawValue == Self.windowID ||
                        $0.title == "Settings"
                    })?
                    .makeKeyAndOrderFront(nil)
            }
        }
    }

    @ViewBuilder
    private func detail(for section: SettingsSection) -> some View {
        switch section {
        case .general: GeneralPane()
        case .menuBar: MenuBarPane()
        case .clocks: ClocksPane()
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
    var header: String?
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
    SettingsWindow()
        .settingsPreviewEnvironment()
        .frame(
            width: SettingsLayout.windowSize.width,
            height: SettingsLayout.windowSize.height
        )
}
#endif
