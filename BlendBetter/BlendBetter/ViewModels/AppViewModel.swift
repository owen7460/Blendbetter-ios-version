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

    /// Saved recipes, newest first.
    @Published private(set) var history: [RecipeHistoryItem] = []

    init() {
        history = HistoryStore.load()
    }
    
    func canAddMoreFruit() -> Bool {
        selectedFruits.count < 3
    }

    func addFruit(_ fruit: String) -> Bool {
        guard !isLoading else { return false }
        guard !selectedFruits.contains(fruit) else { return false }
        guard canAddMoreFruit() else { return false }
        selectedFruits.append(fruit)
        return true
    }

    func toggleFruit(_ fruit: String) {
        guard !isLoading else { return }
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
        guard !finalFruitList.isEmpty, !isLoading else { return }

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
        addToHistory(fruits: fruits, option: option, text: generatedText)
    }

    // MARK: - History

    private func addToHistory(fruits: [String], option: RecipeOption, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = RecipeHistoryItem(
            recipeOptionId: option.id,
            fruits: fruits,
            text: trimmed
        )
        history.insert(item, at: 0)
        if history.count > HistoryStore.maxItems {
            history.removeLast(history.count - HistoryStore.maxItems)
        }
        HistoryStore.save(history)
    }

    func deleteHistory(ids: Set<UUID>) {
        history.removeAll { ids.contains($0.id) }
        HistoryStore.save(history)
    }

    func deleteHistory(_ item: RecipeHistoryItem) {
        deleteHistory(ids: [item.id])
    }

    func clearHistory() {
        history.removeAll()
        HistoryStore.save(history)
    }

    /// Puts a history item's fruits and recipe type back on the Blend page
    /// so the user can generate a fresh variation.
    func blendAgain(_ item: RecipeHistoryItem) {
        guard !isLoading else { return }
        clearAll()
        selectedRecipeOption = item.recipeOption
        selectedFruits = Array(item.fruits.prefix(3))
        selectedTab = 0
    }
}
