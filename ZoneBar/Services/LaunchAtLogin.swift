import ServiceManagement

/// Thin wrapper around SMAppService for managing the login item.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled {
                    return true
                }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notRegistered {
                    return true
                }
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
