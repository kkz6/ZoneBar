import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 320, height: 200)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("is24Hour") private var is24Hour = true
    @AppStorage("showDate") private var showDate = false
    @AppStorage("compactMode") private var compactMode = false
    @State private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("24-hour time format", isOn: $is24Hour)
            Toggle("Show date in menu bar", isOn: $showDate)
            Toggle("Compact mode (abbreviate names)", isOn: $compactMode)

            Divider()

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }

            Spacer()
        }
        .padding(20)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(.system(size: 13, weight: .medium))

            Picker("", selection: $appearanceMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            Spacer()
        }
        .padding(20)
    }
}

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Text("Timely")
                .font(.system(size: 16, weight: .bold))

            Text("Version \(version) (\(build))")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Text("World clocks with meeting awareness")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
