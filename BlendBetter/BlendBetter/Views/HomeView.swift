import SwiftUI
import MarkdownUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showRecipePicker = false
    @State private var showHistory = false
    @State private var showLimitHint = false
    @State private var limitHintToken = 0

    /// Auto-scroll to new text only while the user hasn't scrolled away.
    @State private var isFollowingStream = true
    @State private var isNearBottom = true

    /// "Surprise me" feedback: banner text, a token to time its dismissal, and a counter for the dice animation.
    @State private var surpriseMessage: String?
    @State private var surpriseToken = 0
    @State private var surpriseCount = 0

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

    private func handleSurpriseMe() {
        var picked = false
        withAnimation(.spring(duration: 0.35)) {
            showLimitHint = false
            picked = appViewModel.surpriseMe()
        }
        surpriseCount += 1

        let message: String
        if picked {
            message = "Surprise! " + Self.naturalList(appViewModel.selectedFruits)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            message = "Not enough safe fruits to pick from."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        showSurpriseToast(message)
    }

    private func showSurpriseToast(_ message: String) {
        surpriseToken += 1
        let token = surpriseToken
        withAnimation(.spring(duration: 0.4)) {
            surpriseMessage = message
        }
        AccessibilityNotification.Announcement(message).post()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            guard token == surpriseToken else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                surpriseMessage = nil
            }
        }
    }

    /// "Mango", "Mango & Lime", "Mango, Lychee & Lime"
    private static func naturalList(_ items: [String]) -> String {
        guard items.count > 1, let last = items.last else { return items.first ?? "" }
        return items.dropLast().joined(separator: ", ") + " & " + last
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

                            Button {
                                handleSurpriseMe()
                            } label: {
                                Label("Surprise me", systemImage: "dice")
                                    .font(.subheadline.weight(.semibold))
                                    .symbolEffect(.rotate, value: surpriseCount)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(red: 0.48, green: 0.78, blue: 0.51))
                            .disabled(appViewModel.isSelectionLocked)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Fruit.featured) { fruit in
                                let isSelected = appViewModel.selectedFruits.contains(fruit.name)
                                Button {
                                    handleFruitTap(fruit.name)
                                } label: {
                                    FruitCardView(
                                        fruit: fruit,
                                        isSelected: isSelected,
                                        isDimmed: !isSelected && !appViewModel.canAddMoreFruit()
                                    )
                                }
                                .buttonStyle(.plain)
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

                            if !appViewModel.activePreferences.isEmpty {
                                Button {
                                    appViewModel.selectedTab = 2
                                } label: {
                                    Label("Preferences: \(appViewModel.activePreferences.map(\.label).joined(separator: ", "))", systemImage: "leaf")
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
                            appViewModel.startGeneration()
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

                        if appViewModel.isLoading {
                            Button(role: .destructive) {
                                appViewModel.stopGeneration()
                            } label: {
                                Label("Stop", systemImage: "stop.circle")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }

                        if let errorMessage = appViewModel.errorMessage {
                            VStack(spacing: 10) {
                                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)

                                Button {
                                    appViewModel.startGeneration()
                                } label: {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .buttonStyle(.bordered)
                                .disabled(isGenerateDisabled)
                            }
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
                .onScrollGeometryChange(for: Bool.self) { geo in
                    geo.contentOffset.y + geo.containerSize.height >= geo.contentSize.height - 60
                } action: { _, nearBottom in
                    isNearBottom = nearBottom
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    if newPhase == .interacting {
                        // The user is dragging the list: stop following.
                        isFollowingStream = false
                    } else if newPhase == .idle,
                              oldPhase == .interacting || oldPhase == .decelerating {
                        // Only after a user drag ends: resume if they're back at the bottom.
                        // Our own scrollTo (.animating -> .idle) must not change this, because
                        // content can still be growing when that animation stops.
                        isFollowingStream = isNearBottom
                    }
                }
                .onChange(of: appViewModel.isLoading) { _, isLoading in
                    guard isLoading else { return }
                    isFollowingStream = true
                    withAnimation {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
                .onChange(of: appViewModel.generatedText) { _, _ in
                    guard isFollowingStream else { return }
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
            .overlay(alignment: .top) {
                if let surpriseMessage {
                    SurpriseToast(message: surpriseMessage)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .id(surpriseToken)   // replay the animation on every tap
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) { self.surpriseMessage = nil }
                        }
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
