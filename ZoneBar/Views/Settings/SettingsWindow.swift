import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, SettingsDestination {
    case general
    case menuBar
    case clocks
    case calendar
    case focus
    case appearance
    case about

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .general: return "General"
        case .menuBar: return "Menu Bar"
        case .clocks: return "Clocks"
        case .calendar: return "Calendar"
        case .focus: return "Focus"
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
        case .focus: return "moon.fill"
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
        case .focus: return .indigo
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
        .init("integrations", header: "Integrations", destinations: [.focus, .calendar]),
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
        case .focus: FocusPane()
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
    @State private var hasScrolled = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: SettingsLayout.detailSectionSpacing) {
                    content
                }
                .padding(.horizontal, SettingsLayout.detailHorizontalInset)
                .padding(.top, SettingsLayout.detailTopInset
                    + SettingsLayout.detailHeaderHeight + SettingsLayout.detailSectionSpacing)
                .padding(.bottom, SettingsLayout.detailBottomInset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    SettingsScrollObserver(hasScrolled: $hasScrolled)
                }
            }
            .scrollContentBackground(.hidden)

            HStack(spacing: DS.Spacing.sm) {
                IconTile(symbol: section.symbol, color: section.color, size: 22)
                Text(section.title)
                    .font(.system(size: 18, weight: .semibold))
                Spacer(minLength: 0)
            }
            .frame(height: SettingsLayout.detailHeaderHeight)
            .padding(.horizontal, SettingsLayout.detailHorizontalInset)
            .padding(.vertical, SettingsLayout.detailTopInset)
            .background {
                Rectangle()
                    .fill(.regularMaterial)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.5),
                                .init(color: .black.opacity(0.65), location: 0.8),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .opacity(hasScrolled ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: hasScrolled)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Observes the native clip view so trackpad, wheel, and programmatic scrolling
/// all update the header on macOS 14 and later.
private struct SettingsScrollObserver: NSViewRepresentable {
    @Binding var hasScrolled: Bool

    func makeNSView(context: Context) -> ObserverView {
        ObserverView()
    }

    func updateNSView(_ view: ObserverView, context: Context) {
        view.onScroll = { hasScrolled = $0 }
        view.attachWhenReady()
    }

    final class ObserverView: NSView {
        var onScroll: ((Bool) -> Void)?
        private weak var clipView: NSClipView?
        private var observation: NSObjectProtocol?

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            attachWhenReady()
        }

        func attachWhenReady() {
            DispatchQueue.main.async { [weak self] in
                guard let self, let clip = self.enclosingScrollView?.contentView else { return }
                if self.clipView !== clip {
                    if let observation = self.observation {
                        NotificationCenter.default.removeObserver(observation)
                    }
                    self.clipView = clip
                    clip.postsBoundsChangedNotifications = true
                    self.observation = NotificationCenter.default.addObserver(
                        forName: NSView.boundsDidChangeNotification, object: clip, queue: .main
                    ) { [weak self] _ in
                        guard let self, let clip = self.clipView else { return }
                        self.onScroll?(clip.bounds.minY > 1)
                    }
                }
                self.onScroll?(clip.bounds.minY > 1)
            }
        }

        deinit {
            if let observation { NotificationCenter.default.removeObserver(observation) }
        }
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
