//
//  FruitSearchSection.swift
//  BlendBetter
//

import SwiftUI

private let accentGreen = Color(red: 0.48, green: 0.78, blue: 0.51)

/// Search box for the fruits that aren't on the picture grid,
/// plus removable chips for the ones already picked from search.
struct FruitSearchSection: View {
    @EnvironmentObject var appViewModel: AppViewModel
    /// Same handler the grid uses, so the 3-fruit limit hint behaves identically.
    let onToggle: (String) -> Void

    @State private var query = ""
    @FocusState private var isFocused: Bool

    private static let maxResults = 8

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    /// Searches every fruit, including the featured ones.
    private var results: [Fruit] {
        Array(Fruit.all.filter { $0.matches(trimmedQuery) }.prefix(Self.maxResults))
    }

    /// Selected fruits that don't have a card on the grid.
    private var extraSelected: [String] {
        appViewModel.selectedFruits.filter { Fruit.named($0)?.imageName == nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("More fruits")
                .font(.headline)

            searchField

            if !trimmedQuery.isEmpty {
                let shown = results
                if shown.isEmpty {
                    Text("No fruit matches \"\(trimmedQuery)\"")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(shown) { fruit in
                            resultRow(fruit)
                            if fruit.id != shown.last?.id {
                                Divider().padding(.leading, 54)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if !extraSelected.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(extraSelected, id: \.self) { name in
                            chip(name)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .onChange(of: appViewModel.isSelectionLocked) { _, locked in
            if locked {
                query = ""
                isFocused = false
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search \(Fruit.all.count - Fruit.featured.count) more fruits, e.g. lychee", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resultRow(_ fruit: Fruit) -> some View {
        let isSelected = appViewModel.selectedFruits.contains(fruit.name)
        let canAdd = appViewModel.canAddMoreFruit()

        return Button {
            onToggle(fruit.name)
        } label: {
            HStack(spacing: 12) {
                FruitThumbnail(fruit: fruit, size: 32)

                Text(fruit.name)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? accentGreen : Color.secondary)
                    .opacity(isSelected || canAdd ? 1 : 0.35)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func chip(_ name: String) -> some View {
        HStack(spacing: 6) {
            if let fruit = Fruit.named(name) {
                FruitThumbnail(fruit: fruit, size: 20)
            }
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            Button {
                onToggle(name)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(name)")
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .padding(.vertical, 6)
        .background(accentGreen.opacity(0.15))
        .clipShape(Capsule())
    }
}

/// Small fruit picture, or the colored initial tile when there's no image.
struct FruitThumbnail: View {
    let fruit: Fruit
    let size: CGFloat

    var body: some View {
        Group {
            if let imageName = fruit.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                FruitInitialView(name: fruit.name)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28))
    }
}

#Preview {
    FruitSearchSection(onToggle: { _ in })
        .environmentObject(AppViewModel())
}
