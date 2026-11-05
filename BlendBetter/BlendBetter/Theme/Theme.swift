//
//  Theme.swift
//  BlendBetter
//
//  One place for the app's colors and reusable styles.
//

import SwiftUI

// MARK: - Colors

extension Color {
    /// Builds a color that switches between light and dark mode.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// Main brand green (buttons, selection, tint).
    static let brandGreen = Color(red: 0.48, green: 0.78, blue: 0.51)

    /// Darker green for text on light backgrounds (lighter in dark mode).
    static let brandGreenDeep = Color(
        light: Color(red: 0.18, green: 0.50, blue: 0.29),
        dark: Color(red: 0.62, green: 0.88, blue: 0.64)
    )

    /// Warm yellow for everything "collected" (favorite button, detail heart).
    static let collectYellow = Color(red: 1.0, green: 0.76, blue: 0.0)

    /// Warm red for allergy-related UI.
    static let allergyRed = Color(red: 0.91, green: 0.36, blue: 0.33)

    /// Soft cream page background instead of plain white / black.
    static let appBackground = Color(
        light: Color(red: 0.985, green: 0.97, blue: 0.94),
        dark: Color(red: 0.07, green: 0.08, blue: 0.07)
    )

    /// Card surface that sits on `appBackground`.
    static let cardBackground = Color(
        light: .white,
        dark: Color(red: 0.13, green: 0.14, blue: 0.13)
    )

    /// Subtle fill for inputs and unselected chips inside cards.
    static let fieldBackground = Color(
        light: Color(red: 0.95, green: 0.94, blue: 0.91),
        dark: Color(red: 0.19, green: 0.20, blue: 0.19)
    )
}

// MARK: - Card

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    /// White (or dark) rounded card with a soft shadow.
    func card(padding: CGFloat = 16, cornerRadius: CGFloat = 22) -> some View {
        modifier(CardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Buttons

/// Big filled button used for the main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .brandGreen
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Small rounded "pill" button, e.g. "Surprise me".
struct PillButtonStyle: ButtonStyle {
    var color: Color = .brandGreen
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.brandGreenDeep)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.18), in: Capsule())
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Flow layout

/// Lays children out left to right and wraps to new lines (for chips).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > bounds.width {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
