//
//  Allergen.swift
//  BlendBetter
//

import Foundation

/// Common allergens offered as quick toggles on the Users page.
/// Users can also add their own (e.g. a specific fruit).
nonisolated enum Allergen {
    static let common: [String] = [
        "Milk / dairy",
        "Eggs",
        "Peanuts",
        "Tree nuts",
        "Soy",
        "Wheat / gluten",
        "Sesame",
        "Fish",
        "Shellfish",
        "Coconut",
        "Honey"
    ]

    static func isCommon(_ name: String) -> Bool {
        common.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Whether a selected fruit is itself one of the user's allergens,
    /// e.g. fruit "Kiwi" vs allergen "kiwi", or "Blood Orange" vs "Orange".
    static func fruit(_ fruit: String, conflictsWith allergen: String) -> Bool {
        func normalize(_ s: String) -> String {
            var t = s.lowercased().trimmingCharacters(in: .whitespaces)
            if t.hasSuffix("es") && t.count > 4 { t.removeLast(2) }
            else if t.hasSuffix("s") && t.count > 3 { t.removeLast() }
            return t
        }
        let a = normalize(allergen)
        guard !a.isEmpty else { return false }
        if normalize(fruit) == a { return true }
        let words = fruit.split(separator: " ").map { normalize(String($0)) }
        return words.contains(a)
    }
}
