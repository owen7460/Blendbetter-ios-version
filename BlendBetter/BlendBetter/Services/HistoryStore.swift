//
//  HistoryStore.swift
//  BlendBetter
//

import Foundation

/// Reads / writes a list of recipes as a JSON file in Application Support.
struct RecipeFileStore {
    let fileName: String

    /// Generated recipes (capped at `HistoryStore.maxItems`).
    static let history = RecipeFileStore(fileName: "recipe_history.json")
    /// Recipes the user saved to Collections (no cap).
    static let collections = RecipeFileStore(fileName: "collections.json")

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    func load() -> [RecipeHistoryItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try JSONDecoder().decode([RecipeHistoryItem].self, from: data)
        } catch {
            print("Failed to decode \(fileName):", error.localizedDescription)
            return []
        }
    }

    func save(_ items: [RecipeHistoryItem]) {
        do {
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save \(fileName):", error.localizedDescription)
        }
    }
}

enum HistoryStore {
    /// Oldest history entries beyond this are dropped.
    static let maxItems = 20
}
