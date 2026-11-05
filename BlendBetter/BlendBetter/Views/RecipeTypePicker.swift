//
//  RecipeTypePicker.swift
//  BlendBetter
//

import SwiftUI

/// Horizontal row of drink-type chips (Smoothie, Cocktail, …) at the top of the Blend page.
struct RecipeTypePicker: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RecipeOption.options) { option in
                    chip(option)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    private func chip(_ option: RecipeOption) -> some View {
        let isSelected = option.id == appViewModel.selectedRecipeOption.id

        return Button {
            guard !isSelected else { return }
            withAnimation(.snappy(duration: 0.25)) {
                appViewModel.selectedRecipeOption = option
            }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 6) {
                Text(option.emoji)
                Text(option.label)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                Capsule().fill(isSelected ? Color.brandGreen : Color.cardBackground)
            )
            .shadow(color: .black.opacity(isSelected ? 0.12 : 0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
