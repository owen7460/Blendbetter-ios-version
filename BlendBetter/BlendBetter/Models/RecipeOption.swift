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
    let subtitle: String

    static let options: [RecipeOption] = [
        RecipeOption(
            id: "smoothie",
            emoji: "🥤",
            label: "Smoothie",
            prefix: "Please generate a smoothie recipe using",
            subtitle: "Let's choose your fruits for smoothie."
        ),
        RecipeOption(
            id: "cocktail",
            emoji: "🍹",
            label: "Cocktail",
            prefix: "Please generate a cocktail recipe using",
            subtitle: "Let's choose your fruits for cocktail."
        ),
        RecipeOption(
            id: "bubbleTea",
            emoji: "🧋",
            label: "Bubble tea",
            prefix: "Please generate a bubble tea recipe using",
            subtitle: "Let's choose your fruits for bubble tea."
        ),
        RecipeOption(
            id: "slushie",
            emoji: "🍧",
            label: "Slushie",
            prefix: "Please generate a slushie recipe using",
            subtitle: "Let's choose your fruits for slushie."
        ),
        RecipeOption(
            id: "icedBlendedDrink",
            emoji: "🧊",
            label: "Iced blended drink",
            prefix: "Please generate an iced blended drink recipe using",
            subtitle: "Let's choose your fruits for iced blended drink."
        ),
        RecipeOption(
            id: "yogurtDrink",
            emoji: "🥛",
            label: "Yogurt drink",
            prefix: "Please generate a yogurt drink recipe using",
            subtitle: "Let's choose your fruits for yogurt drink."
        )
    ]
}
