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
        .frame(width: 360, height: 260)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("is24Hour") private var is24Hour = true
    @AppStorage("showDate") private var showDate = false
    @AppStorage("compactMode") private var compactMode = false
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Toggle("24-hour time format", isOn: $is24Hour)
            Toggle("Show date in menu bar", isOn: $showDate)
            Toggle("Compact mode (abbreviate names)", isOn: $compactMode)

            Divider()

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
        }
        .padding()
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
        Form {
            Picker("Appearance", selection: $appearanceMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.radioGroup)
        }
        .padding()
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
        VStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Timely")
                .font(.system(size: 18, weight: .bold))

            Text("Version \(version) (\(build))")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Text("World clocks with meeting awareness")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
