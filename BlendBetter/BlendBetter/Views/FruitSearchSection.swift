//
//  FruitSearchSection.swift
//  BlendBetter
//

import SwiftUI

private let accentGreen = Color.brandGreen

/// Search box for all fruits, shown above the picture grid.
/// Picked fruits show up in the selection tray at the bottom of the Blend page.
struct FruitSearchSection: View {
    @EnvironmentObject var appViewModel: AppViewModel
    /// Same handler the grid uses, so the 3-fruit limit hint behaves identically.
    let onToggle: (String) -> Void
    /// Tells the Blend page when the search field is being typed in,
    /// so it can hide the bottom tray and scroll the field to the top.
    @Binding var isSearching: Bool

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
            searchField

            // Hidden while typing so the results sit right under the field.
            if trimmedQuery.isEmpty {
                // "Camera" is a tappable link that switches to the Camera tab.
                Text("Or tap one of the \(Fruit.featured.count) common fruits below. You can also use the [Camera](blendbetter://camera) to recognize one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .tint(Color.brandGreenDeep)
                    .environment(\.openURL, OpenURLAction { _ in
                        isFocused = false
                        appViewModel.selectedTab = 3
                        return .handled
                    })
                    .padding(.leading, 4)
            }

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
        .onChange(of: isFocused) { _, focused in
            isSearching = focused
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search \(Fruit.all.count) fruits, e.g. lychee", text: $query)
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
    FruitSearchSection(onToggle: { _ in }, isSearching: .constant(false))
        .environmentObject(AppViewModel())
}
