//
//  CollectButton.swift
//  BlendBetter
//

import SwiftUI

/// Heart button next to "Clear & Start Over". Tap to add the recipe to
/// Collections, tap again to remove it.
struct CollectButton: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let recipe: RecipeHistoryItem

    var body: some View {
        let isCollected = appViewModel.isCollected(recipe)

        Button {
            appViewModel.toggleCollection(recipe)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: isCollected ? "heart.fill" : "heart")
                .font(.title3.weight(.semibold))
                .foregroundStyle(isCollected ? Color.white : Color.collectYellow)
                .symbolEffect(.bounce, value: isCollected)
                .frame(width: 56)
                .frame(maxHeight: .infinity)
                .background(isCollected ? Color.collectYellow : Color.collectYellow.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(.easeInOut(duration: 0.2), value: isCollected)
        }
        .accessibilityLabel(isCollected ? "Remove from Collections" : "Add to Collections")
    }
}

extension Color {
    /// Warm yellow used for everything "collected" (favorite button, detail toolbar heart).
    static let collectYellow = Color(red: 1.0, green: 0.76, blue: 0.0)
}
