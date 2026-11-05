//
//  HistoryStore.swift
//  BlendBetter
//

import Foundation

/// Reads / writes the recipe history as a JSON file in Application Support.
enum HistoryStore {
    /// Oldest entries beyond this are dropped.
    static let maxItems = 20

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("recipe_history.json")
    }

    static func load() -> [RecipeHistoryItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try JSONDecoder().decode([RecipeHistoryItem].self, from: data)
        } catch {
            print("Failed to decode history:", error.localizedDescription)
            return []
        }
    }

    static func save(_ items: [RecipeHistoryItem]) {
        do {
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save history:", error.localizedDescription)
        }
    }
}
