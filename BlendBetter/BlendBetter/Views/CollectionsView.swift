import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var searchText = ""

    private var filteredItems: [RecipeHistoryItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return appViewModel.collections }
        return appViewModel.collections.filter { item in
            item.recipeName.localizedCaseInsensitiveContains(query)
                || item.fruitSummary.localizedCaseInsensitiveContains(query)
                || item.recipeOption.label.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appViewModel.collections.isEmpty {
                    ContentUnavailableView {
                        Label("No Collections Yet", systemImage: "heart")
                    } description: {
                        Text("Tap the heart next to \"Clear & Start Over\" after generating a recipe to save it here.")
                    }
                } else if filteredItems.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink(value: item) {
                                HistoryRowView(item: item, showsDate: true)
                            }
                        }
                        .onDelete { offsets in
                            let ids = Set(offsets.map { filteredItems[$0].id })
                            withAnimation {
                                appViewModel.removeFromCollections(ids: ids)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $searchText, prompt: "Search fruits or recipes")
            .navigationTitle("Collections")
            .navigationDestination(for: RecipeHistoryItem.self) { item in
                HistoryDetailView(item: item, source: .collections)
            }
        }
    }
}

#Preview {
    CollectionsView()
        .environmentObject(AppViewModel())
}
