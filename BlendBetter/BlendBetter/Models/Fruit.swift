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
    /// Asset name in Assets.xcassets, e.g. "Dragon Fruit" -> "dragon_fruit".
    /// Optional so callers can still fall back to the initial tile if an image is ever missing.
    let imageName: String?
    /// Shown as a picture card on the Blend grid (the rest are found via search).
    let isFeatured: Bool
    /// Other names used for search and camera recognition.
    let aliases: [String]

    init(id: Int, name: String, aliases: [String] = [], isFeatured: Bool = false) {
        self.id = id
        self.name = name
        self.imageName = name.lowercased().replacingOccurrences(of: " ", with: "_")
        self.aliases = aliases
        self.isFeatured = isFeatured
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
        all.filter(\.isFeatured)
    }

    static let all: [Fruit] = [
        // Featured on the Blend grid
        Fruit(id: 1, name: "Apple", isFeatured: true),
        Fruit(id: 2, name: "Banana", isFeatured: true),
        Fruit(id: 3, name: "Orange", isFeatured: true),
        Fruit(id: 4, name: "Pineapple", aliases: ["Ananas"], isFeatured: true),
        Fruit(id: 5, name: "Strawberry", isFeatured: true),
        Fruit(id: 6, name: "Watermelon", isFeatured: true),
        Fruit(id: 7, name: "Kiwi", aliases: ["Kiwifruit"], isFeatured: true),
        Fruit(id: 8, name: "Mango", isFeatured: true),
        Fruit(id: 9, name: "Peach", isFeatured: true),

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
        Fruit(id: 60, name: "Date", aliases: ["Medjool"]),

        // More berries
        Fruit(id: 61, name: "Boysenberry"),
        Fruit(id: 62, name: "Lingonberry", aliases: ["Cowberry"]),
        Fruit(id: 63, name: "Huckleberry"),
        Fruit(id: 64, name: "Golden Berry", aliases: ["Physalis", "Cape Gooseberry", "Inca Berry"]),
        Fruit(id: 65, name: "Sea Buckthorn"),
        Fruit(id: 66, name: "Aronia", aliases: ["Chokeberry"]),
        Fruit(id: 67, name: "Kiwiberry", aliases: ["Hardy Kiwi", "Baby Kiwi"]),
        Fruit(id: 68, name: "Muscadine"),
        Fruit(id: 69, name: "Chinese Bayberry", aliases: ["Yangmei", "Waxberry", "Red Bayberry"]),

        // More stone & pome fruits
        Fruit(id: 70, name: "Sour Cherry", aliases: ["Morello Cherry", "Tart Cherry"]),
        Fruit(id: 71, name: "Pluot"),
        Fruit(id: 72, name: "Jujube", aliases: ["Red Date", "Chinese Date"]),
        Fruit(id: 73, name: "Hawthorn", aliases: ["Haw", "Hawberry"]),

        // More melons
        Fruit(id: 74, name: "Hami Melon"),
        Fruit(id: 75, name: "Galia Melon"),
        Fruit(id: 76, name: "Korean Melon", aliases: ["Chamoe"]),
        Fruit(id: 77, name: "Horned Melon", aliases: ["Kiwano"]),

        // More citrus
        Fruit(id: 78, name: "Tangelo", aliases: ["Ugli Fruit", "Minneola"]),
        Fruit(id: 79, name: "Satsuma"),
        Fruit(id: 80, name: "Calamansi", aliases: ["Calamondin"]),
        Fruit(id: 81, name: "Key Lime"),
        Fruit(id: 82, name: "Meyer Lemon"),
        Fruit(id: 83, name: "Bergamot"),
        Fruit(id: 84, name: "Finger Lime"),
        Fruit(id: 85, name: "Citron", aliases: ["Etrog"]),

        // More tropical
        Fruit(id: 86, name: "Cherimoya"),
        Fruit(id: 87, name: "Sugar Apple", aliases: ["Custard Apple", "Sweetsop"]),
        Fruit(id: 88, name: "Sapodilla", aliases: ["Chikoo"]),
        Fruit(id: 89, name: "Mamey Sapote", aliases: ["Mamey"]),
        Fruit(id: 90, name: "Salak", aliases: ["Snake Fruit"]),
        Fruit(id: 91, name: "Wax Apple", aliases: ["Java Apple", "Rose Apple"]),
        Fruit(id: 92, name: "Langsat", aliases: ["Lanzones", "Duku"]),
        Fruit(id: 93, name: "Jabuticaba"),
        Fruit(id: 94, name: "Acerola", aliases: ["Barbados Cherry"]),
        Fruit(id: 95, name: "Pitanga", aliases: ["Surinam Cherry"]),
        Fruit(id: 96, name: "Feijoa", aliases: ["Pineapple Guava"]),
        Fruit(id: 97, name: "Lucuma"),
        Fruit(id: 98, name: "Tamarind"),

        // Others
        Fruit(id: 99, name: "Prickly Pear", aliases: ["Cactus Pear"]),
        Fruit(id: 100, name: "Monk Fruit", aliases: ["Luo Han Guo"])
    ]
}
