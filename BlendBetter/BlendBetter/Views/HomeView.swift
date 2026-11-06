import SwiftUI
import MarkdownUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
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

    /// While generating or after a recipe is done, the page shows the result
    /// instead of the fruit picker.
    /// True while the user is typing in the fruit search field.
    @State private var isSearching = false

    private var isResultMode: Bool {
        appViewModel.isLoading || appViewModel.isFinished
    }

    /// The bottom bar (selection tray / Stop / Clear) is hidden:
    /// - while typing in the search field, since it would sit on top of the keyboard;
    /// - in picker mode with no fruits selected, since there's nothing to show or generate yet.
    private var showsBottomBar: Bool {
        if isResultMode { return true }
        return !isSearching && !appViewModel.selectedFruits.isEmpty
    }

    private var isGenerateDisabled: Bool {
        appViewModel.finalFruitList.isEmpty
            || appViewModel.isSelectionLocked
            || !appViewModel.conflictingFruits.isEmpty
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 22) {
                        if isResultMode {
                            resultContent
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            pickerContent
                                .transition(.opacity)
                        }

                        // Extra room while searching, so the field can scroll to the top
                        // even when there's little content below it.
                        if isSearching && !isResultMode {
                            Color.clear
                                .frame(height: 360)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.easeInOut(duration: 0.3), value: isResultMode)
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
                    // Result mode starts at the top: summary card + loading animation.
                    proxy.scrollTo("top", anchor: .top)
                }
                .onChange(of: appViewModel.generatedText) { _, _ in
                    guard isFollowingStream, !appViewModel.generatedText.isEmpty else { return }
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
                .onChange(of: isSearching) { _, searching in
                    guard searching else { return }
                    // Put the search field at the top so results have room above the keyboard.
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("search", anchor: .top)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if showsBottomBar {
                        bottomBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isSearching)
                .animation(.spring(duration: 0.35), value: appViewModel.selectedFruits.isEmpty)
            }
            .background(Color.appBackground.ignoresSafeArea())
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
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.brandGreenDeep)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel("History")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handleSurpriseMe()
                    } label: {
                        Image(systemName: "dice")
                            .font(.system(size: 17, weight: .semibold))
                            .symbolEffect(.rotate, value: surpriseCount)
                    }
                    // Only useful while picking fruits.
                    .disabled(appViewModel.isSelectionLocked)
                    .accessibilityLabel("Surprise me")
                    .accessibilityHint("Picks 2 to 3 random fruits for you.")
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
            }
            .sheet(isPresented: $appViewModel.showAIConsent) {
                AIConsentView()
            }
        }
    }

    // MARK: - Picker mode

    private var pickerContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What are we blending?")
                    .font(.title2.weight(.bold))
                Text("Pick a drink, then 1–3 fruits from your fridge.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .id("top")

            RecipeTypePicker()

            FruitSearchSection(onToggle: { handleFruitTap($0) }, isSearching: $isSearching)
                .id("search")

            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: columns, spacing: 12) {
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

                if showLimitHint {
                    Label("You can choose up to \(AppViewModel.maxFruits) fruits. Tap a selected fruit to remove it.", systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal)


            if !appViewModel.conflictingFruits.isEmpty {
                Label("\(appViewModel.conflictingFruits.joined(separator: ", ")) is on your allergy list. Remove it to generate.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.allergyRed)
                    .padding(.horizontal)
            }

            if !appViewModel.allergens.isEmpty || !appViewModel.activePreferences.isEmpty {
                dietSummaryCard
                    .padding(.horizontal)
            }

            if let errorMessage = appViewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.allergyRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card(padding: 14, cornerRadius: 18)
                    .padding(.horizontal)
            }
        }
    }

    /// Compact "what we avoid" card; tap to edit on the Allergies tab.
    private var dietSummaryCard: some View {
        Button {
            appViewModel.selectedTab = 2
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    if !appViewModel.allergens.isEmpty {
                        Label("Avoiding \(appViewModel.allergens.joined(separator: ", "))", systemImage: "exclamationmark.shield.fill")
                            .foregroundStyle(Color.allergyRed)
                    }
                    if !appViewModel.activePreferences.isEmpty {
                        Label(appViewModel.activePreferences.map(\.label).joined(separator: ", "), systemImage: "leaf.fill")
                            .foregroundStyle(Color.brandGreenDeep)
                    }
                }
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .card(padding: 14, cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Result mode

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            recipeSummaryCard
                .id("top")

            // Show the animation until the first words of the recipe arrive.
            if appViewModel.isLoading && appViewModel.generatedText.isEmpty {
                BlendingLoadingView(
                    fruits: appViewModel.finalFruitList,
                    fallbackEmoji: appViewModel.selectedRecipeOption.emoji
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if !appViewModel.generatedText.isEmpty {
                Markdown(appViewModel.generatedText)
                    .markdownTheme(.blendBetter)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card(padding: 20)

                AIDisclaimer(allergens: appViewModel.currentRecipe?.allergens ?? appViewModel.allergens)
            }

            if appViewModel.isFinished {
                Label("Saved to History", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    /// "🥤 Smoothie · Mango, Kiwi" header shown above the recipe.
    private var recipeSummaryCard: some View {
        HStack(spacing: 14) {
            Text(appViewModel.selectedRecipeOption.emoji)
                .font(.system(size: 30))
                .frame(width: 56, height: 56)
                .background(Color.brandGreen.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(appViewModel.selectedRecipeOption.label)
                    .font(.headline)
                Text(appViewModel.finalFruitList.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            HStack(spacing: -10) {
                ForEach(appViewModel.finalFruitList, id: \.self) { name in
                    if let fruit = Fruit.named(name) {
                        FruitThumbnail(fruit: fruit, size: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32 * 0.28, style: .continuous)
                                    .stroke(Color.cardBackground, lineWidth: 2)
                            )
                    }
                }
            }
        }
        .card(padding: 14)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        Group {
            if appViewModel.isLoading {
                Button {
                    appViewModel.stopGeneration()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: .allergyRed))
            } else if appViewModel.isFinished {
                HStack(spacing: 12) {
                    Button {
                        appViewModel.clearAll()
                    } label: {
                        Text("Clear & Start Over")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if let recipe = appViewModel.currentRecipe {
                        CollectButton(recipe: recipe)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            } else {
                SelectionTray(
                    onRemove: { handleFruitTap($0) },
                    isGenerateDisabled: isGenerateDisabled
                )
            }
        }
        .padding(SelectionTray.edgeInset)
        // Keep everything (e.g. scrolling fruit chips) inside the rounded card.
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        // Floating Liquid Glass card, matching the iOS 26 tab bar below it.
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .animation(.easeInOut(duration: 0.25), value: appViewModel.isLoading)
        .animation(.easeInOut(duration: 0.25), value: appViewModel.isFinished)
        .animation(.spring(duration: 0.3), value: appViewModel.selectedFruits)
    }

    // MARK: - Actions

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
        withAnimation(.spring(duration: 0.3)) {
            showLimitHint = false
            appViewModel.toggleFruit(name)
        }
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
}
