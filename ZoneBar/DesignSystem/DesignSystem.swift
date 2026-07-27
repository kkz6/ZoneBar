import SwiftUI

// MARK: - Design Tokens

enum DS {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    enum Radius {
        static let window: CGFloat = 20
        static let card: CGFloat = 17
        static let row: CGFloat = 13
        static let control: CGFloat = 13
        static let selection: CGFloat = 11
        static let tile: CGFloat = 8
    }

    enum Size {
        static let rowHeight: CGFloat = 46
        static let tile: CGFloat = 26
        static let popoverWidth: CGFloat = 320
    }

    /// Visible, theme-adaptive border used on every card and input.
    static let borderColor = Color.gray.opacity(0.55)
    /// Lighter hairline used to separate rows inside a card.
    static let dividerColor = Color.gray.opacity(0.28)
}

// MARK: - Icon Tile

/// SF Symbol on a rounded, tinted square — the colored icons in the sidebar / rows.
struct IconTile: View {
    let symbol: String
    var color: Color = .accentColor
    var size: CGFloat = DS.Size.tile

    var body: some View {
        RoundedRectangle(cornerRadius: DS.Radius.tile, style: .continuous)
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .shadow(color: color.opacity(0.25), radius: 1, y: 0.5)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

/// Supplemental copy below a settings group. It intentionally adds no
/// horizontal padding so its text shares the pane's content gutter.
struct SettingsNote: View {
    let text: String
    var fontSize: CGFloat = 12

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Settings Card

/// Grouped card that lays its children out as rows separated by hairline dividers,
/// matching the rounded grouped lists in the reference design.
struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.borderColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 7, y: 2)
    }
}

/// Public-API separator for rows inside `SettingsCard`.
struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.dividerColor)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

// MARK: - Setting Row

/// One row inside a SettingsCard: optional leading icon, title + optional subtitle,
/// and a trailing control (toggle, picker, value, chevron…).
struct SettingRow<Trailing: View>: View {
    var icon: String?
    var iconColor: Color = .accentColor
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            if let icon {
                IconTile(symbol: icon, color: iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: DS.Spacing.md)

            trailing
        }
        .padding(.horizontal, SettingsLayout.cardHorizontalInset)
        .frame(minHeight: DS.Size.rowHeight)
    }
}

extension SettingRow where Trailing == EmptyView {
    init(icon: String? = nil, iconColor: Color = .accentColor, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = EmptyView()
    }
}

// MARK: - Brand accent

extension Color {
    /// Mint/seafoam accent used across toggles and controls.
    static let zoneAccent = Color(red: 0.36, green: 0.82, blue: 0.64)
}

// MARK: - Toggle styling helper

extension View {
    /// Standard compact toggle used by settings rows. It inherits the app's
    /// environment tint, so the settings framework is reusable across brands.
    func settingsToggle() -> some View {
        self.toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
    }
}

// MARK: - Segmented Selector

struct SegmentOption<Value: Hashable>: Identifiable {
    let value: Value
    let title: String
    var symbol: String? = nil
    var glyph: String? = nil

    var id: String { title }
}

/// Card-style segmented control: a row of tappable cards (icon or glyph) with a
/// label beneath each, the selected one outlined in the accent colour.
struct SegmentedSelector<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [SegmentOption<Value>]

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            ForEach(options) { option in
                segment(option, isSelected: option.value == selection)
            }
        }
    }

    private func segment(_ option: SegmentOption<Value>, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) { selection = option.value }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(Color.accentColor.opacity(0.12)) : AnyShapeStyle(Color.primary.opacity(0.05)))
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(
                            isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(DS.borderColor),
                            lineWidth: isSelected ? 2 : 1
                        )

                    Group {
                        if let symbol = option.symbol {
                            Image(systemName: symbol).font(.system(size: 17, weight: .medium))
                        } else if let glyph = option.glyph {
                            Text(glyph).font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                }
                .frame(height: 46)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(option.title)
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])

            Text(option.title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A labelled segmented control sized to sit as a row inside a SettingsCard.
struct SegmentedRow<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [SegmentOption<Value>]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13))
            SegmentedSelector(selection: $selection, options: options)
        }
        .padding(.horizontal, SettingsLayout.cardHorizontalInset)
        .padding(.vertical, SettingsLayout.cardVerticalInset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
