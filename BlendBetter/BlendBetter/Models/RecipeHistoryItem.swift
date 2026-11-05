//
//  RecipeHistoryItem.swift
//  BlendBetter
//

import Foundation

/// One generated recipe saved to history.
nonisolated struct RecipeHistoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let recipeOptionId: String
    let fruits: [String]
    let text: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        recipeOptionId: String,
        fruits: [String],
        text: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.recipeOptionId = recipeOptionId
        self.fruits = fruits
        self.text = text
    }

    /// The recipe type this item was generated with (falls back to the first option).
    @MainActor
    var recipeOption: RecipeOption {
        RecipeOption.options.first { $0.id == recipeOptionId } ?? RecipeOption.options[0]
    }

    /// The first non-empty line of the markdown, stripped of heading / emphasis markers.
    /// Usually the recipe's name, e.g. "Tropical Mango Smoothie".
    var recipeName: String {
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""

        let cleaned = firstLine
            .trimmingCharacters(in: CharacterSet(charactersIn: "#*_` :"))
            .trimmingCharacters(in: .whitespaces)

        return cleaned.isEmpty ? fruits.joined(separator: ", ") : cleaned
    }

    var fruitSummary: String {
        fruits.joined(separator: ", ")
    }
}
