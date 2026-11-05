//
//  Fruit.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//

import Foundation

nonisolated struct Fruit: Identifiable, Hashable {
    let id: Int
    let name: String
    /// Asset name. Only the featured fruits on the Blend grid have one.
    let imageName: String?
    /// Other names used for search and camera recognition.
    let aliases: [String]

    init(id: Int, name: String, imageName: String? = nil, aliases: [String] = []) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.aliases = aliases
    }

    /// Case-insensitive match on the name or any alias.
    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return false }
        return ([name] + aliases).contains { $0.localizedCaseInsensitiveContains(q) }
    }

    static func named(_ name: String) -> Fruit? {
        all.first { $0.name == name }
    }

    /// The fruits shown as picture cards on the Blend page.
    static var featured: [Fruit] {
        all.filter { $0.imageName != nil }
    }

    static let all: [Fruit] = [
        // Featured (with images)
        Fruit(id: 1, name: "Apple", imageName: "apple"),
        Fruit(id: 2, name: "Banana", imageName: "banana"),
        Fruit(id: 3, name: "Orange", imageName: "orange"),
        Fruit(id: 4, name: "Pineapple", imageName: "pineapple", aliases: ["Ananas"]),
        Fruit(id: 5, name: "Strawberry", imageName: "strawberry"),
        Fruit(id: 6, name: "Watermelon", imageName: "watermelon"),
        Fruit(id: 7, name: "Kiwi", imageName: "kiwi", aliases: ["Kiwifruit"]),
        Fruit(id: 8, name: "Mango", imageName: "mango"),
        Fruit(id: 9, name: "Peach", imageName: "peach"),

        // Pome & stone fruits
        Fruit(id: 10, name: "Pear"),
        Fruit(id: 11, name: "Asian Pear", aliases: ["Nashi"]),
        Fruit(id: 12, name: "Quince"),
        Fruit(id: 13, name: "Cherry", aliases: ["Cherries"]),
        Fruit(id: 14, name: "Apricot"),
        Fruit(id: 15, name: "Plum"),
        Fruit(id: 16, name: "Nectarine"),
        Fruit(id: 17, name: "Loquat"),

        // Berries
        Fruit(id: 18, name: "Blueberry", aliases: ["Blueberries"]),
        Fruit(id: 19, name: "Raspberry", aliases: ["Raspberries"]),
        Fruit(id: 20, name: "Blackberry", aliases: ["Blackberries"]),
        Fruit(id: 21, name: "Cranberry", aliases: ["Cranberries"]),
        Fruit(id: 22, name: "Gooseberry"),
        Fruit(id: 23, name: "Mulberry"),
        Fruit(id: 24, name: "Blackcurrant", aliases: ["Black Currant", "Cassis"]),
        Fruit(id: 25, name: "Redcurrant", aliases: ["Red Currant"]),
        Fruit(id: 26, name: "Elderberry"),
        Fruit(id: 27, name: "Goji Berry", aliases: ["Wolfberry"]),
        Fruit(id: 28, name: "Acai", aliases: ["Açaí"]),
        Fruit(id: 29, name: "Grape", aliases: ["Grapes"]),

        // Citrus
        Fruit(id: 30, name: "Lemon"),
        Fruit(id: 31, name: "Lime"),
        Fruit(id: 32, name: "Grapefruit"),
        Fruit(id: 33, name: "Tangerine"),
        Fruit(id: 34, name: "Mandarin"),
        Fruit(id: 35, name: "Clementine"),
        Fruit(id: 36, name: "Pomelo"),
        Fruit(id: 37, name: "Kumquat"),
        Fruit(id: 38, name: "Yuzu"),
        Fruit(id: 39, name: "Blood Orange"),

        // Melons
        Fruit(id: 40, name: "Cantaloupe", aliases: ["Rockmelon", "Muskmelon"]),
        Fruit(id: 41, name: "Honeydew", aliases: ["Honeydew Melon"]),

        // Tropical
        Fruit(id: 42, name: "Coconut"),
        Fruit(id: 43, name: "Papaya"),
        Fruit(id: 44, name: "Passion Fruit", aliases: ["Passionfruit", "Maracuja"]),
        Fruit(id: 45, name: "Guava"),
        Fruit(id: 46, name: "Lychee", aliases: ["Litchi"]),
        Fruit(id: 47, name: "Longan"),
        Fruit(id: 48, name: "Rambutan"),
        Fruit(id: 49, name: "Dragon Fruit", aliases: ["Pitaya", "Pitahaya"]),
        Fruit(id: 50, name: "Durian"),
        Fruit(id: 51, name: "Jackfruit"),
        Fruit(id: 52, name: "Mangosteen"),
        Fruit(id: 53, name: "Starfruit", aliases: ["Carambola", "Star Fruit"]),
        Fruit(id: 54, name: "Soursop", aliases: ["Guanabana"]),
        Fruit(id: 55, name: "Avocado"),
        Fruit(id: 56, name: "Plantain"),

        // Others
        Fruit(id: 57, name: "Pomegranate"),
        Fruit(id: 58, name: "Persimmon"),
        Fruit(id: 59, name: "Fig"),
        Fruit(id: 60, name: "Date", aliases: ["Medjool"])
    ]
}
