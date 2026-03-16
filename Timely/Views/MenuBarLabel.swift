import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var clockManager: ClockManager

    var body: some View {
        let text = clockManager.menuBarText()
        if text.isEmpty {
            Image(systemName: "clock")
        } else {
            Text(text)
        }
    }
}
