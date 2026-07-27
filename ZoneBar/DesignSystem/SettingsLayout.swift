import SwiftUI

/// Geometry shared by the settings window, sidebar, detail panes, and AppKit
/// titlebar controls. Change these values in one place to retheme the shell.
enum SettingsLayout {
    static let windowSize = CGSize(width: 600, height: 560)

    static let sidebarWidth: CGFloat = 200
    static let sidebarOuterInset: CGFloat = 12
    static let sidebarRowInnerInset: CGFloat = 8
    static let sidebarRowHeight: CGFloat = 34
    static let sidebarFirstRowTop: CGFloat = 48

    static let detailHorizontalInset: CGFloat = 16
    static let detailTopInset: CGFloat = 13
    static let detailBottomInset: CGFloat = 22
    static let detailHeaderHeight: CGFloat = 26
    static let detailSectionSpacing: CGFloat = 14
    static let groupHeaderSpacing: CGFloat = 6
    static let cardHorizontalInset: CGFloat = 12
    static let cardVerticalInset: CGFloat = 10

    /// The titlebar controls and detail header share this horizontal baseline.
    static let titlebarControlCenterFromTop =
        detailTopInset + detailHeaderHeight / 2

    /// The close button starts on the same leading grid line as sidebar icons.
    static let trafficLightLeading =
        sidebarOuterInset + sidebarRowInnerInset
}

/// A destination displayed by the reusable settings sidebar and detail header.
protocol SettingsDestination: Identifiable, Hashable {
    var title: String { get }
    var symbol: String { get }
    var color: Color { get }
}

/// One labelled group in the reusable settings sidebar.
struct SettingsSidebarGroup<Destination: SettingsDestination>: Identifiable {
    let id: String
    let header: String?
    let destinations: [Destination]

    init(_ id: String, header: String? = nil, destinations: [Destination]) {
        self.id = id
        self.header = header
        self.destinations = destinations
    }
}

/// Complete macOS settings chrome. Apps provide destinations, sidebar groups,
/// and a detail view; the shell owns the shared geometry and materials.
struct SettingsShell<Destination: SettingsDestination, Detail: View>: View {
    @Binding var selection: Destination
    let groups: [SettingsSidebarGroup<Destination>]
    @ViewBuilder let detail: (Destination) -> Detail

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(
                selection: $selection,
                groups: groups
            )
            .frame(width: SettingsLayout.sidebarWidth)
            .frame(maxHeight: .infinity)
            .background(VisualEffectView(material: .sidebar).ignoresSafeArea())

            Divider()

            ScrollView {
                detail(selection)
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            idealWidth: SettingsLayout.windowSize.width,
            maxWidth: .infinity,
            idealHeight: SettingsLayout.windowSize.height,
            maxHeight: .infinity
        )
        .background(VisualEffectView(material: .underWindowBackground).ignoresSafeArea())
        .background(WindowConfigurator(
            size: SettingsLayout.windowSize,
            trafficLightLeading: SettingsLayout.trafficLightLeading,
            trafficLightCenterFromTop: SettingsLayout.titlebarControlCenterFromTop
        ))
        .ignoresSafeArea()
    }
}

private struct SettingsSidebar<Destination: SettingsDestination>: View {
    @Binding var selection: Destination
    let groups: [SettingsSidebarGroup<Destination>]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: SettingsLayout.sidebarFirstRowTop)

            ForEach(groups) { group in
                if let header = group.header {
                    Text(header)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, SettingsLayout.sidebarRowInnerInset)
                        .padding(.top, DS.Spacing.md)
                        .padding(.bottom, DS.Spacing.xs)
                }

                ForEach(group.destinations) { destination in
                    SettingsSidebarRow(
                        destination: destination,
                        isSelected: selection == destination
                    ) {
                        selection = destination
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, SettingsLayout.sidebarOuterInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct SettingsSidebarRow<Destination: SettingsDestination>: View {
    let destination: Destination
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                IconTile(symbol: destination.symbol, color: destination.color, size: 22)
                Text(destination.title)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, SettingsLayout.sidebarRowInnerInset)
            .frame(height: SettingsLayout.sidebarRowHeight)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var background: Color {
        if isSelected { return .primary.opacity(0.10) }
        if isHovering { return .primary.opacity(0.05) }
        return .clear
    }
}
