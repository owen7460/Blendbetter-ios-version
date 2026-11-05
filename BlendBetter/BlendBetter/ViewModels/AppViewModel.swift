import Foundation
import Combine

final class AppViewModel: ObservableObject {
    @Published var selectedFruits: [String] = []
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

    /// Ingredients the user is allergic to; added to every prompt.
    @Published private(set) var allergens: [String] = []
    private static let allergensKey = "allergens"

    /// Ids of the dietary preferences that are switched on.
    @Published private(set) var dietaryPreferenceIDs: [String] = []
    private static let preferencesKey = "dietaryPreferences"

    /// Whether the user agreed to send their recipe inputs (fruits, allergies,
    /// preferences) to the AI service. Required before the first generation.
    @Published private(set) var hasAIConsent = false
    /// Drives the consent sheet on the Blend page.
    @Published var showAIConsent = false
    private static let aiConsentKey = "aiDataSharingConsent"

    init() {
        history = RecipeFileStore.history.load()
        collections = RecipeFileStore.collections.load()
        allergens = UserDefaults.standard.stringArray(forKey: Self.allergensKey) ?? []
        dietaryPreferenceIDs = UserDefaults.standard.stringArray(forKey: Self.preferencesKey) ?? []
        hasAIConsent = UserDefaults.standard.bool(forKey: Self.aiConsentKey)
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
        pendingText = ""
        generatedText = ""
        errorMessage = nil
        isLoading = false
        isFinished = false
        currentRecipe = nil
    }

    /// Camera-detected fruits are added to `selectedFruits` directly,
    /// so the selection is the single source of truth.
    var finalFruitList: [String] {
        selectedFruits
    }

    var promptText: String {
        let joined = finalFruitList.joined(separator: ", ")
        var text = "\(selectedRecipeOption.prefix) \(joined)."
        if !allergens.isEmpty {
            text += " IMPORTANT: I am allergic to \(allergens.joined(separator: ", "))."
            text += " The recipe must not contain any of these, or any ingredient made from"
            text += " or likely to contain them (including milks, yogurts, syrups, toppings and garnishes)."
            text += " Use safe substitutes where needed, and end with a short note listing what was avoided."
        }
        let preferences = activePreferences
        if !preferences.isEmpty {
            text += " Also follow these dietary preferences: "
            text += preferences.map(\.instruction).joined(separator: " ")
        }
        return text
    }

    /// Selected fruits that are on the user's allergy list.
    var conflictingFruits: [String] {
        finalFruitList.filter { fruit in
            allergens.contains { Allergen.fruit(fruit, conflictsWith: $0) }
        }
    }

    private var generationTask: Task<Void, Never>?

    /// Streamed text not shown yet. Deltas are batched and flushed every 0.1s
    /// so the Markdown view re-renders a few times a second, not on every token.
    private var pendingText = ""
    private var isFlushScheduled = false
    private static let flushInterval: TimeInterval = 0.1

    /// Starts generating (also used by "Try Again").
    func startGeneration() {
        guard generationTask == nil else { return }
        // Nothing leaves the device until the user has agreed.
        guard hasAIConsent else {
            showAIConsent = true
            return
        }
        generationTask = Task { [weak self] in
            await self?.generateRecipe()
            self?.generationTask = nil
        }
    }

    func grantAIConsent() {
        hasAIConsent = true
        UserDefaults.standard.set(true, forKey: Self.aiConsentKey)
    }

    func revokeAIConsent() {
        hasAIConsent = false
        UserDefaults.standard.set(false, forKey: Self.aiConsentKey)
    }

    /// Cancels the request and goes back to the selection state.
    func stopGeneration() {
        generationTask?.cancel()
    }

    private func generateRecipe() async {
        guard !finalFruitList.isEmpty, !isSelectionLocked, conflictingFruits.isEmpty else { return }

        isLoading = true
        isFinished = false
        errorMessage = nil
        generatedText = ""

        let prompt = promptText
        // Capture what this recipe was generated from, in case the user
        // changes the selection while the response is still streaming.
        let fruits = finalFruitList
        let option = selectedRecipeOption
        let avoided = allergens
        let preferenceLabels = activePreferences.map(\.label)

        do {
            try await RecipeAPI.streamRecipe(
                prompt: prompt,
                onDelta: { delta in
                    self.appendStreamedText(delta)
                },
                onFinish: {
                    self.finishGeneration(fruits: fruits, option: option, allergens: avoided, preferences: preferenceLabels)
                }
            )
            // Stopped before the recipe finished (a finished one is kept).
            if Task.isCancelled && isLoading {
                resetAfterFailure(message: nil)
                return
            }
            // The stream can close without sending a "finish" event.
            if isLoading {
                finishGeneration(fruits: fruits, option: option, allergens: avoided, preferences: preferenceLabels)
            }
        } catch {
            let cancelled = Task.isCancelled
                || error is CancellationError
                || (error as? URLError)?.code == .cancelled
            resetAfterFailure(message: cancelled ? nil : Self.friendlyMessage(for: error))
        }
    }

    private func appendStreamedText(_ delta: String) {
        pendingText += delta
        guard !isFlushScheduled else { return }
        isFlushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.flushInterval) { [weak self] in
            self?.flushStreamedText()
        }
    }

    private func flushStreamedText() {
        isFlushScheduled = false
        guard !pendingText.isEmpty else { return }
        generatedText += pendingText
        pendingText = ""
    }

    /// Back to the editable state; `message == nil` means the user stopped it.
    private func resetAfterFailure(message: String?) {
        pendingText = ""
        isLoading = false
        isFinished = false
        generatedText = ""
        errorMessage = message
    }

    private static func friendlyMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "You're offline. Check your internet connection and try again."
            case .timedOut:
                return "The server took too long to respond. Please try again."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "Can't reach the BlendBetter server right now. Please try again later."
            default:
                break
            }
        }
        let nsError = error as NSError
        if nsError.domain == "RecipeAPI" {
            switch nsError.code {
            case 429:
                return "Too many requests. Please wait a moment and try again."
            case 500...599:
                return "The BlendBetter server is having trouble. Please try again in a moment."
            default:
                return "Something went wrong (error \(nsError.code)). Please try again."
            }
        }
        return "Something went wrong. Please try again."
    }

    private func finishGeneration(fruits: [String], option: RecipeOption, allergens: [String], preferences: [String]) {
        guard isLoading else { return }
        flushStreamedText()   // make sure the last batch is shown and saved
        isLoading = false
        isFinished = true
        currentRecipe = addToHistory(fruits: fruits, option: option, text: generatedText, allergens: allergens, preferences: preferences)
    }

    // MARK: - History

    @discardableResult
    private func addToHistory(fruits: [String], option: RecipeOption, text: String, allergens: [String], preferences: [String]) -> RecipeHistoryItem? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let item = RecipeHistoryItem(
            recipeOptionId: option.id,
            fruits: fruits,
            text: trimmed,
            allergens: allergens.isEmpty ? nil : allergens,
            preferences: preferences.isEmpty ? nil : preferences
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

    // MARK: - Surprise me

    /// Replaces the selection with 2–3 random fruits that aren't on the allergy list.
    /// At least one comes from the picture grid, so the user sees a card light up;
    /// the rest can be any fruit. Returns false if there aren't enough safe fruits.
    @discardableResult
    func surpriseMe() -> Bool {
        guard !isSelectionLocked else { return false }

        func isSafe(_ fruit: String) -> Bool {
            !allergens.contains { Allergen.fruit(fruit, conflictsWith: $0) }
        }
        let safeFruits = Fruit.all.map(\.name).filter(isSafe)
        let safeFeatured = Fruit.featured.map(\.name).filter(isSafe)
        guard safeFruits.count >= 2 else { return false }

        let count = min(Int.random(in: 2...Self.maxFruits), safeFruits.count)

        func randomPick() -> [String] {
            // No safe grid fruit (e.g. allergic to all of them): pick from everything.
            guard let anchor = safeFeatured.randomElement() else {
                return Array(safeFruits.shuffled().prefix(count))
            }
            let others = safeFruits.filter { $0 != anchor }.shuffled().prefix(count - 1)
            return ([anchor] + others).shuffled()
        }

        var pick = randomPick()
        // Avoid handing back exactly the same set twice in a row.
        var attempts = 0
        while Set(pick) == Set(selectedFruits) && attempts < 5 {
            pick = randomPick()
            attempts += 1
        }

        selectedFruits = pick
        errorMessage = nil
        return true
    }

    // MARK: - Dietary preferences

    var activePreferences: [DietaryPreference] {
        DietaryPreference.all.filter { dietaryPreferenceIDs.contains($0.id) }
    }

    func isPreferenceOn(_ preference: DietaryPreference) -> Bool {
        dietaryPreferenceIDs.contains(preference.id)
    }

    func setPreference(_ preference: DietaryPreference, isOn: Bool) {
        dietaryPreferenceIDs.removeAll { $0 == preference.id }
        if isOn {
            dietaryPreferenceIDs.append(preference.id)
        }
        UserDefaults.standard.set(dietaryPreferenceIDs, forKey: Self.preferencesKey)
    }

    // MARK: - Allergens

    /// Allergens that aren't in the common list (typed in by the user).
    var customAllergens: [String] {
        allergens.filter { !Allergen.isCommon($0) }
    }

    func isAllergenSelected(_ name: String) -> Bool {
        allergens.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

    func toggleAllergen(_ name: String) {
        if isAllergenSelected(name) {
            allergens.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
        } else {
            allergens.append(name)
        }
        saveAllergens()
    }

    /// Longest custom allergen name, and how many custom ones can be added.
    /// Keeps the prompt well under the server's size limit.
    static let maxAllergenLength = 40
    static let maxCustomAllergens = 20

    /// Adds a typed-in allergen. Returns false if it's empty, already listed,
    /// or the custom list is full. Long names are cut to `maxAllergenLength`.
    @discardableResult
    func addCustomAllergen(_ raw: String) -> Bool {
        let name = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxAllergenLength))
            .trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !isAllergenSelected(name),
              customAllergens.count < Self.maxCustomAllergens else { return false }
        allergens.append(name)
        saveAllergens()
        return true
    }

    func removeAllergens(_ names: [String]) {
        allergens.removeAll { a in names.contains { $0.caseInsensitiveCompare(a) == .orderedSame } }
        saveAllergens()
    }

    func clearAllergens() {
        allergens.removeAll()
        saveAllergens()
    }

    private func saveAllergens() {
        UserDefaults.standard.set(allergens, forKey: Self.allergensKey)
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
