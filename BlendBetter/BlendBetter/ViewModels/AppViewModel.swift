import Foundation
import Combine

final class AppViewModel: ObservableObject {
    @Published var selectedFruits: [String] = []
    @Published var detectedFruit: String? = nil
    @Published var selectedRecipeOption: RecipeOption = RecipeOption.options[0]

    @Published var generatedText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var selectedTab: Int = 0
    
    @Published var isFinished: Bool = false

    /// True while generating and after a recipe is done. The selection stays
    /// locked until the user taps "Clear & Start Over".
    var isSelectionLocked: Bool {
        isLoading || isFinished
    }

    /// Saved recipes, newest first.
    @Published private(set) var history: [RecipeHistoryItem] = []

    /// Recipes the user added to Collections, most recently added first.
    @Published private(set) var collections: [RecipeHistoryItem] = []

    /// The recipe currently shown on the Blend page once generation is finished.
    @Published private(set) var currentRecipe: RecipeHistoryItem? = nil

    init() {
        history = RecipeFileStore.history.load()
        collections = RecipeFileStore.collections.load()
    }
    
    /// Maximum number of fruits in one recipe.
    static let maxFruits = 3

    func canAddMoreFruit() -> Bool {
        selectedFruits.count < Self.maxFruits
    }

    func addFruit(_ fruit: String) -> Bool {
        guard !isSelectionLocked else { return false }
        guard !selectedFruits.contains(fruit) else { return false }
        guard canAddMoreFruit() else { return false }
        selectedFruits.append(fruit)
        return true
    }

    func toggleFruit(_ fruit: String) {
        guard !isSelectionLocked else { return }
        if selectedFruits.contains(fruit) {
            selectedFruits.removeAll { $0 == fruit }
        } else {
            _ = addFruit(fruit)
        }
    }

    func clearAll() {
        selectedFruits = []
        detectedFruit = nil
        generatedText = ""
        errorMessage = nil
        isLoading = false
        isFinished = false
        currentRecipe = nil
    }

    var finalFruitList: [String] {
        if !selectedFruits.isEmpty {
            return selectedFruits
        }
        if let detectedFruit, !detectedFruit.isEmpty {
            return [detectedFruit]
        }
        return []
    }

    var promptText: String {
        let joined = finalFruitList.joined(separator: ", ")
        return "\(selectedRecipeOption.prefix) \(joined)."
    }

    func generateRecipe() async {
        guard !finalFruitList.isEmpty, !isSelectionLocked else { return }

        isLoading = true
        isFinished = false
        errorMessage = nil
        generatedText = ""

        let prompt = promptText
        // Capture what this recipe was generated from, in case the user
        // changes the selection while the response is still streaming.
        let fruits = finalFruitList
        let option = selectedRecipeOption

        do {
            try await RecipeAPI.streamRecipe(
                prompt: prompt,
                onDelta: { delta in
                    self.generatedText += delta
                },
                onFinish: {
                    self.finishGeneration(fruits: fruits, option: option)
                }
            )
            // The stream can close without sending a "finish" event.
            if isLoading {
                finishGeneration(fruits: fruits, option: option)
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            self.isFinished = false
        }
    }

    private func finishGeneration(fruits: [String], option: RecipeOption) {
        guard isLoading else { return }
        isLoading = false
        isFinished = true
        currentRecipe = addToHistory(fruits: fruits, option: option, text: generatedText)
    }

    // MARK: - History

    @discardableResult
    private func addToHistory(fruits: [String], option: RecipeOption, text: String) -> RecipeHistoryItem? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let item = RecipeHistoryItem(
            recipeOptionId: option.id,
            fruits: fruits,
            text: trimmed
        )
        history.insert(item, at: 0)
        if history.count > HistoryStore.maxItems {
            history.removeLast(history.count - HistoryStore.maxItems)
        }
        RecipeFileStore.history.save(history)
        return item
    }

    func deleteHistory(ids: Set<UUID>) {
        history.removeAll { ids.contains($0.id) }
        RecipeFileStore.history.save(history)
    }

    func deleteHistory(_ item: RecipeHistoryItem) {
        deleteHistory(ids: [item.id])
    }

    func clearHistory() {
        history.removeAll()
        RecipeFileStore.history.save(history)
    }

    // MARK: - Collections

    func isCollected(_ item: RecipeHistoryItem) -> Bool {
        collections.contains { $0.id == item.id }
    }

    /// Adds the recipe to Collections, or removes it if it's already there.
    func toggleCollection(_ item: RecipeHistoryItem) {
        if isCollected(item) {
            collections.removeAll { $0.id == item.id }
        } else {
            collections.insert(item, at: 0)
        }
        RecipeFileStore.collections.save(collections)
    }

    func removeFromCollections(ids: Set<UUID>) {
        collections.removeAll { ids.contains($0.id) }
        RecipeFileStore.collections.save(collections)
    }

    /// Puts a history item's fruits and recipe type back on the Blend page
    /// so the user can generate a fresh variation.
    func blendAgain(_ item: RecipeHistoryItem) {
        guard !isLoading else { return }
        clearAll()
        selectedRecipeOption = item.recipeOption
        selectedFruits = Array(item.fruits.prefix(Self.maxFruits))
        selectedTab = 0
    }
}
