//
//  RecipeOption.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//
import Foundation

struct RecipeOption: Identifiable, Hashable {
    let id: String
    let emoji: String
    let label: String
    let prefix: String

    static let options: [RecipeOption] = [
        RecipeOption(
            id: "smoothie",
            emoji: "🥤",
            label: "Smoothie",
            prefix: "Please generate a smoothie recipe using"
        ),
        RecipeOption(
            id: "cocktail",
            emoji: "🍹",
            label: "Cocktail",
            prefix: "Please generate a cocktail recipe using"
        ),
        RecipeOption(
            id: "bubbleTea",
            emoji: "🧋",
            label: "Bubble tea",
            prefix: "Please generate a bubble tea recipe using"
        ),
        RecipeOption(
            id: "slushie",
            emoji: "🍧",
            label: "Slushie",
            prefix: "Please generate a slushie recipe using"
        ),
        RecipeOption(
            id: "icedBlendedDrink",
            emoji: "🧊",
            label: "Iced blended drink",
            prefix: "Please generate an iced blended drink recipe using"
        ),
        RecipeOption(
            id: "yogurtDrink",
            emoji: "🥛",
            label: "Yogurt drink",
            prefix: "Please generate a yogurt drink recipe using"
        )
    ]
}
