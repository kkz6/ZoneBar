import SwiftUI

struct AboutPane: View {
    @Environment(AppUpdater.self) private var updater
    var usesApplicationIcon = true

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        SettingsPane(section: SettingsSection.about) {
            VStack(spacing: DS.Spacing.md) {
                appIcon
                    .frame(width: 84, height: 84)

                Text("ZoneBar")
                    .font(.system(size: 22, weight: .bold))

                Text("World clocks for your menu bar")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("Version \(version) (\(build))")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.lg)

            SettingsGroup {
                Button {
                    updater.checkForUpdates()
                } label: {
                    SettingRow(icon: "arrow.triangle.2.circlepath", iconColor: .blue, title: "Check for Updates") {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                SettingsDivider()
                LinkRow(icon: "chevron.left.forwardslash.chevron.right", color: .black, title: "Source Code", url: "https://github.com/kkz6/ZoneBar")
                SettingsDivider()
                LinkRow(icon: "ant.fill", color: .red, title: "Report an Issue", url: "https://github.com/kkz6/ZoneBar/issues")
            }

            Link(destination: URL(string: "https://karti.dev")!) {
                Text("Made by karti.dev")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var appIcon: some View {
        if usesApplicationIcon,
           let nsImage = NSApplication.shared.applicationIconImage {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
        } else {
            IconTile(symbol: "globe", color: .teal, size: 84)
        }
    }
}

private struct LinkRow: View {
    let icon: String
    let color: Color
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            SettingRow(icon: icon, iconColor: color, title: title) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("About") {
    AboutPane(usesApplicationIcon: false)
        .settingsPreviewEnvironment()
        .frame(width: 400, height: 520, alignment: .top)
}
#endif
