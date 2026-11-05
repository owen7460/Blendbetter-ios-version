//
//  HistoryView.swift
//  BlendBetter
//

import SwiftUI
import MarkdownUI

private let brandGreen = Color(red: 0.48, green: 0.78, blue: 0.51)

// MARK: - List

struct HistoryView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var showClearConfirm = false

    private struct DaySection: Identifiable {
        let day: Date
        let items: [RecipeHistoryItem]
        var id: Date { day }
    }

    private var filteredItems: [RecipeHistoryItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return appViewModel.history }
        return appViewModel.history.filter { item in
            item.recipeName.localizedCaseInsensitiveContains(query)
                || item.fruitSummary.localizedCaseInsensitiveContains(query)
                || item.recipeOption.label.localizedCaseInsensitiveContains(query)
        }
    }

    private var sections: [DaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredItems) { calendar.startOfDay(for: $0.createdAt) }
        return grouped
            .map { DaySection(day: $0.key, items: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appViewModel.history.isEmpty {
                    ContentUnavailableView(
                        "No History Yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Recipes you generate will be saved here automatically.")
                    )
                } else if filteredItems.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(sections) { section in
                            Section(sectionTitle(for: section.day)) {
                                ForEach(section.items) { item in
                                    NavigationLink(value: item) {
                                        HistoryRowView(item: item)
                                    }
                                }
                                .onDelete { offsets in
                                    let ids = Set(offsets.map { section.items[$0].id })
                                    withAnimation {
                                        appViewModel.deleteHistory(ids: ids)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $searchText, prompt: "Search fruits or recipes")
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RecipeHistoryItem.self) { item in
                HistoryDetailView(item: item, onBlendAgain: { dismiss() })
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) {
                        showClearConfirm = true
                    }
                    .disabled(appViewModel.history.isEmpty)
                }
            }
            .confirmationDialog(
                "Delete all history?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    withAnimation {
                        appViewModel.clearHistory()
                    }
                }
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Row

struct HistoryRowView: View {
    let item: RecipeHistoryItem
    /// Show the date instead of only the time (used where items span many days).
    var showsDate: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(item.recipeOption.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(brandGreen.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.recipeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text("\(item.recipeOption.label) · \(item.fruitSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Group {
                if showsDate {
                    Text(item.createdAt, format: .dateTime.month(.abbreviated).day())
                } else {
                    Text(item.createdAt, style: .time)
                }
            }
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail

struct HistoryDetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    enum Source {
        case history
        case collections
    }

    let item: RecipeHistoryItem
    /// Where the detail was opened from; decides what "Delete" removes.
    var source: Source = .history
    /// Called after "Blend Again" so the parent can close the history sheet.
    var onBlendAgain: () -> Void = {}

    @State private var showDeleteConfirm = false
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                Markdown(item.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .textSelection(.enabled)

                Button {
                    appViewModel.blendAgain(item)
                    onBlendAgain()
                } label: {
                    Label("Blend Again", systemImage: "arrow.clockwise")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(brandGreen)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(appViewModel.isLoading)
                .opacity(appViewModel.isLoading ? 0.5 : 1)
            }
            .padding()
        }
        .navigationTitle(item.recipeOption.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    appViewModel.toggleCollection(item)
                } label: {
                    Image(systemName: appViewModel.isCollected(item) ? "heart.fill" : "heart")
                        .foregroundStyle(appViewModel.isCollected(item) ? Color.pink : Color.accentColor)
                        .symbolEffect(.bounce, value: appViewModel.isCollected(item))
                }
                .accessibilityLabel(appViewModel.isCollected(item) ? "Remove from Collections" : "Add to Collections")

                ShareLink(item: item.text) {
                    Image(systemName: "square.and.arrow.up")
                }

                Menu {
                    Button {
                        UIPasteboard.general.string = item.text
                        copied = true
                    } label: {
                        Label("Copy Recipe", systemImage: "doc.on.doc")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(
                            source == .collections ? "Remove from Collections" : "Delete from History",
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            source == .collections ? "Remove from Collections?" : "Delete from History?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(source == .collections ? "Remove" : "Delete", role: .destructive) {
                switch source {
                case .history:
                    appViewModel.deleteHistory(item)
                case .collections:
                    appViewModel.removeFromCollections(ids: [item.id])
                }
                dismiss()
            }
        }
        .alert("Copied to clipboard", isPresented: $copied) {
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.createdAt.formatted(date: .long, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let allergens = item.allergens, !allergens.isEmpty {
                Label("Avoided: \(allergens.joined(separator: ", "))", systemImage: "exclamationmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(item.fruits, id: \.self) { name in
                    HStack(spacing: 6) {
                        if let imageName = Fruit.named(name)?.imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 22, height: 22)
                                .clipShape(Circle())
                        }
                        Text(name)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(brandGreen.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppViewModel())
}
