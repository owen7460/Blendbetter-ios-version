import SwiftUI
import MarkdownUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showRecipePicker = false
    @State private var showHistory = false
    @State private var showLimitHint = false
    @State private var limitHintToken = 0

    private var isGenerateDisabled: Bool {
        appViewModel.finalFruitList.isEmpty
            || appViewModel.isSelectionLocked
            || !appViewModel.conflictingFruits.isEmpty
    }

    private var selectionSummary: String {
        let fruits = appViewModel.finalFruitList
        guard !fruits.isEmpty else { return "No fruits selected (0/\(AppViewModel.maxFruits))" }
        return "You selected: \(fruits.joined(separator: ", ")) (\(fruits.count)/\(AppViewModel.maxFruits))"
    }

    private func handleFruitTap(_ name: String) {
        let isSelected = appViewModel.selectedFruits.contains(name)
        if !isSelected && !appViewModel.canAddMoreFruit() {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            limitHintToken += 1
            let token = limitHintToken
            withAnimation { showLimitHint = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if token == limitHintToken {
                    withAnimation { showLimitHint = false }
                }
            }
            return
        }
        withAnimation { showLimitHint = false }
        appViewModel.toggleFruit(name)
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("\(appViewModel.selectedRecipeOption.emoji) \(appViewModel.selectedRecipeOption.subtitle)")
                                .font(.headline)
                                .multilineTextAlignment(.center)

                            Text("Please choose 1-3 kinds of fruits, you can check what you have in your fridge")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Fruit.featured) { fruit in
                                let isSelected = appViewModel.selectedFruits.contains(fruit.name)
                                FruitCardView(
                                    fruit: fruit,
                                    isSelected: isSelected,
                                    isDimmed: !isSelected && !appViewModel.canAddMoreFruit()
                                )
                                .onTapGesture {
                                    handleFruitTap(fruit.name)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .allowsHitTesting(!appViewModel.isSelectionLocked)
                        .opacity(appViewModel.isSelectionLocked ? 0.5 : 1)

                        FruitSearchSection(onToggle: { handleFruitTap($0) })
                            .allowsHitTesting(!appViewModel.isSelectionLocked)
                            .opacity(appViewModel.isSelectionLocked ? 0.5 : 1)

                        VStack( spacing: 8) {
                            Text(selectionSummary)
                                .font(.subheadline)

                            if showLimitHint {
                                Label("You can choose up to \(AppViewModel.maxFruits) fruits. Tap a selected fruit to remove it.", systemImage: "exclamationmark.circle")
                                    .font(.footnote)
                                    .foregroundStyle(.orange)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }

                            if !appViewModel.conflictingFruits.isEmpty {
                                Label("\(appViewModel.conflictingFruits.joined(separator: ", ")) is on your allergy list. Remove it to generate.", systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            if !appViewModel.allergens.isEmpty {
                                Button {
                                    appViewModel.selectedTab = 2
                                } label: {
                                    Label("Avoiding: \(appViewModel.allergens.joined(separator: ", "))", systemImage: "exclamationmark.shield")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }

                            if let detectedFruit = appViewModel.detectedFruit {
                                Text("Camera detected: \(detectedFruit)")
                                    .font(.footnote)
                                    .foregroundStyle(.green)
                            }
                        }

                        Button {
                            Task {
                                await appViewModel.generateRecipe()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if appViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(appViewModel.isLoading ? "Generating…" : "Generate")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.48, green: 0.78, blue: 0.51))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        .disabled(isGenerateDisabled)
                        .opacity(isGenerateDisabled ? 0.5 : 1)
                        .animation(.easeInOut(duration: 0.2), value: appViewModel.isLoading)

                        // Show the animation until the first words of the recipe arrive.
                        if appViewModel.isLoading && appViewModel.generatedText.isEmpty {
                            BlendingLoadingView(
                                fruits: appViewModel.finalFruitList,
                                fallbackEmoji: appViewModel.selectedRecipeOption.emoji
                            )
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        if let errorMessage = appViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.footnote)
                                .padding(.horizontal)
                        }

                        if !appViewModel.generatedText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Result")
                                    .font(.headline)

                                Group {
                                    Markdown(appViewModel.generatedText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                }
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                if appViewModel.isFinished {
                                    HStack(spacing: 12) {
                                        Button {
                                            appViewModel.clearAll()
                                        } label: {
                                            Text("Clear & Start Over")
                                                .fontWeight(.bold)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color(red: 0.48, green: 0.78, blue: 0.51))
                                                .foregroundColor(.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }

                                        if let recipe = appViewModel.currentRecipe {
                                            CollectButton(recipe: recipe)
                                        }
                                    }
                                    .fixedSize(horizontal: false, vertical: true)
                                    .transition(.opacity)
                                }
                            }
                            .padding(.horizontal)
                        }

                        Color.clear
                            .frame(height: 10)
                            .id("bottomAnchor")
                    }
                    .padding(.vertical)
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.easeInOut(duration: 0.25), value: appViewModel.isLoading)
                .animation(.easeInOut(duration: 0.25), value: appViewModel.generatedText.isEmpty)
                .onChange(of: appViewModel.generatedText) { _, _ in
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .principal) {
                    Text("BlendBetter")
                        .font(.title)
                        .fontWeight(.semibold)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .medium))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showRecipePicker = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .disabled(appViewModel.isSelectionLocked)
                }
            }
            .sheet(isPresented: $showRecipePicker) {
                RecipeTypePickerView()
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
            }
        }
    }
}
