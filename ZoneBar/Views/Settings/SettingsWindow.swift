import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
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

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: $selection)
                .frame(width: 200)
                .frame(maxHeight: .infinity)
                .background(VisualEffectView(material: .sidebar).ignoresSafeArea())

            Divider()

            ScrollView {
                detail
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(idealWidth: 600, maxWidth: .infinity, idealHeight: 560, maxHeight: .infinity)
        .background(VisualEffectView(material: .underWindowBackground).ignoresSafeArea())
        .background(WindowConfigurator(size: CGSize(width: 600, height: 560)))
        .ignoresSafeArea()
        .onAppear {
            // Show a Dock icon + ⌘Tab entry while settings is open so the app is easy to switch to.
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .general: GeneralPane()
        case .menuBar: MenuBarPane()
        case .clocks: ClocksPane()
        case .appearance: AppearancePane()
        case .about: AboutPane()
        }
    }
}

// MARK: - Sidebar

private struct SettingsSidebar: View {
    @Binding var selection: SettingsSection

    // Grouped like the reference: a top item, then labelled sections.
    private let groups: [(header: String?, items: [SettingsSection])] = [
        (nil, [.general]),
        ("Clocks", [.clocks, .menuBar]),
        ("App", [.appearance, .about]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Leave room for the traffic-light buttons.
            Color.clear.frame(height: 28)

            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                if let header = group.header {
                    Text(header)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, DS.Spacing.md)
                        .padding(.bottom, DS.Spacing.xs)
                }

                ForEach(group.items) { section in
                    SidebarRow(section: section, isSelected: selection == section) {
                        selection = section
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct SidebarRow: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                IconTile(symbol: section.symbol, color: section.color, size: 22)
                Text(section.title)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var background: Color {
        if isSelected { return .primary.opacity(0.10) }
        if isHovering { return .primary.opacity(0.05) }
        return .clear
    }
}

// MARK: - Pane scaffold

/// Shared layout for a settings detail pane: a large titled header followed by a
/// scrollable stack of grouped card sections.
struct SettingsPane<Content: View>: View {
    let section: SettingsSection
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: DS.Spacing.sm) {
                IconTile(symbol: section.symbol, color: section.color, size: 22)
                Text(section.title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.bottom, DS.Spacing.xs)

            content
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.top, 22)
        .padding(.bottom, DS.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A labelled group: an optional section header above a SettingsCard.
struct SettingsGroup<Content: View>: View {
    var header: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            if let header {
                SectionHeader(title: header)
            }
            SettingsCard {
                content
            }
        }
    }
}
