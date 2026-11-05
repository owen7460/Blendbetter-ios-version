//
//  FruitSearchSection.swift
//  BlendBetter
//

import SwiftUI

private let accentGreen = Color.brandGreen

/// Search box for the fruits that aren't on the picture grid.
/// Picked fruits show up in the selection tray at the bottom of the Blend page.
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("More fruits")
                .font(.headline)
                .padding(.leading, 4)

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
                    .card(padding: 0, cornerRadius: 18)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
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
