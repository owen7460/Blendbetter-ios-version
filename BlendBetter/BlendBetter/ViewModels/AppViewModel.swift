//
//  AppViewModel.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//
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
    
    
    func canAddMoreFruit() -> Bool {
        selectedFruits.count < 3
    }

    func addFruit(_ fruit: String) -> Bool {
        guard !selectedFruits.contains(fruit) else { return false }
        guard canAddMoreFruit() else { return false }
        selectedFruits.append(fruit)
        return true
    }

    func toggleFruit(_ fruit: String) {
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
        guard !finalFruitList.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        generatedText = ""

        let prompt = promptText

        do {
            try await RecipeAPI.streamRecipe(
                prompt: prompt,
                onDelta: { delta in
                    self.generatedText += delta
                    self.isLoading = false
                },
                onFinish: {
                    self.isLoading = false
                }
            )
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
