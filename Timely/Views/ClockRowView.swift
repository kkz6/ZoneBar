import SwiftUI

struct ClockRowView: View {
    let clock: WorldClock
    let offset: TimeInterval
    let is24Hour: Bool
    let compact: Bool
    let onToggleVisibility: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Day/night indicator with background
            ZStack {
                Circle()
                    .fill(clock.isDaytime ? Color.yellow.opacity(0.15) : Color.indigo.opacity(0.15))
                    .frame(width: 28, height: 28)

                Image(systemName: clock.isDaytime ? "sun.max.fill" : "moon.fill")
                    .foregroundStyle(clock.isDaytime ? .yellow : .indigo)
                    .font(.system(size: 13))
            }

            // City name and info
            VStack(alignment: .leading, spacing: 2) {
                if isEditing {
                    TextField("Name", text: $editName, onCommit: {
                        if !editName.isEmpty {
                            onRename(editName)
                        }
                        isEditing = false
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                } else {
                    Text(compact ? clock.compactName : clock.name)
                        .font(.system(size: 13, weight: .medium))
                        .onTapGesture(count: 2) {
                            editName = clock.name
                            isEditing = true
                        }
                }

                HStack(spacing: 4) {
                    if let country = clock.country.isEmpty ? nil : clock.country {
                        Text(country)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    Text(clock.gmtOffsetString)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(minHeight: 28, alignment: .leading)

            Spacer()

            // Relative day label
            if let dayLabel = clock.relativeDayLabel(offset: offset) {
                Text(dayLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.08), in: Capsule())
            }

            // Time display
            Text(clock.formattedTime(offset: offset, is24Hour: is24Hour))
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(clock.isDaytime ? .primary : .secondary)
                .frame(minWidth: 65, alignment: .trailing)

            // Visibility & actions (shown on hover)
            if isHovering {
                HStack(spacing: 6) {
                    Button(action: onToggleVisibility) {
                        Image(systemName: clock.showInMenuBar ? "eye.fill" : "eye.slash")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(clock.showInMenuBar ? "Hide from menu bar" : "Show in menu bar")

                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove clock")
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(isHovering ? Color.primary.opacity(0.04) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
