//
//  DietaryPreference.swift
//  BlendBetter
//

import Foundation

/// Optional diet rules the user can switch on; each adds one instruction to the prompt.
nonisolated struct DietaryPreference: Identifiable, Hashable {
    let id: String
    let label: String
    let detail: String
    let instruction: String

    static let all: [DietaryPreference] = [
        DietaryPreference(
            id: "vegan",
            label: "Vegan",
            detail: "No dairy, eggs, honey or other animal products",
            instruction: "Make it fully vegan: no dairy, eggs, honey or any other animal products."
        ),
        DietaryPreference(
            id: "lowSugar",
            label: "Low sugar",
            detail: "No added sugar or syrups",
            instruction: "Keep it low in sugar: no added sugar or syrups; rely on the fruit's natural sweetness."
        ),
        DietaryPreference(
            id: "noAlcohol",
            label: "No alcohol",
            detail: "Cocktails become mocktails",
            instruction: "Make it alcohol-free; for a cocktail, make a mocktail version."
        ),
        DietaryPreference(
            id: "noCaffeine",
            label: "No caffeine",
            detail: "Bubble tea uses a caffeine-free base",
            instruction: "Make it caffeine-free; for bubble tea, use a caffeine-free base such as rooibos or herbal tea."
        )
    ]
}
