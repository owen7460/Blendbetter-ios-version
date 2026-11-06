//
//  SelectionTray.swift
//  BlendBetter
//

import SwiftUI

/// Bottom bar on the Blend page: the picked fruits (with names) and the Generate button.
struct SelectionTray: View {
    @EnvironmentObject var appViewModel: AppViewModel
    /// Removes a fruit (same handler as the grid).
    let onRemove: (String) -> Void
    let isGenerateDisabled: Bool

    /// Must match the horizontal padding the Blend page puts around the tray.
    static let edgeInset: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Your blend")
                    .font(.subheadline.weight(.semibold))
                Text("\(appViewModel.selectedFruits.count)/\(AppViewModel.maxFruits)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(appViewModel.selectedRecipeOption.emoji) \(appViewModel.selectedRecipeOption.label)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appViewModel.selectedFruits, id: \.self) { name in
                        fruitChip(name)
                            .transition(.scale.combined(with: .opacity))
                    }
                    if appViewModel.selectedFruits.count < AppViewModel.maxFruits {
                        placeholderChip
                    }
                }
                .padding(.vertical, 2)
                // Inset the chips to line up with the rest of the tray...
                .padding(.horizontal, Self.edgeInset)
            }
            // ...but let the scroll area reach the card's edges, so chips are cut
            // off at the edge of the card (with a soft fade) instead of mid-card.
            .padding(.horizontal, -Self.edgeInset)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.04),
                        .init(color: .black, location: 0.96),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            if !appViewModel.conflictingFruits.isEmpty {
                Label("Remove fruits on your allergy list to generate", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.allergyRed)
            }

            Button {
                appViewModel.startGeneration()
            } label: {
                Label(
                    appViewModel.errorMessage == nil ? "Generate" : "Try Again",
                    systemImage: appViewModel.errorMessage == nil ? "sparkles" : "arrow.clockwise"
                )
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isGenerateDisabled)
            .padding(.top, 2)
        }
    }

    private func fruitChip(_ name: String) -> some View {
        let isConflicting = appViewModel.conflictingFruits.contains(name)

        return HStack(spacing: 8) {
            if let fruit = Fruit.named(name) {
                FruitThumbnail(fruit: fruit, size: 28)
            }
            Text(name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Button {
                onRemove(name)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(name)")
        }
        .padding(.leading, 5)
        .padding(.trailing, 6)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(isConflicting ? Color.allergyRed.opacity(0.15) : Color.cardBackground)
        )
        .overlay(
            Capsule().stroke(isConflicting ? Color.allergyRed : Color.primary.opacity(0.08), lineWidth: isConflicting ? 1.5 : 1)
        )
    }

    private var placeholderChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .font(.caption.weight(.bold))
            Text(appViewModel.selectedFruits.isEmpty ? "Pick 1–3 fruits" : "Add fruit")
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .overlay(
            Capsule().strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        )
        .accessibilityHidden(true)
    }
}
