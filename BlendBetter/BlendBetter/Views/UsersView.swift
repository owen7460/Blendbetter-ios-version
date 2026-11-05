import SwiftUI

/// "Allergies & Diet": dietary preference toggles plus allergen chips.
struct UsersView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var newAllergen = ""
    @State private var showClearConfirm = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Every recipe follows these settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    preferencesCard
                    allergiesCard
                    disclaimer
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Allergies & Diet")
            .confirmationDialog(
                "Clear all allergies?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    withAnimation {
                        appViewModel.clearAllergens()
                    }
                }
            }
        }
    }

    // MARK: - Dietary preferences

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Dietary preferences", systemImage: "leaf.fill", color: .brandGreenDeep)

            VStack(spacing: 0) {
                ForEach(DietaryPreference.all) { preference in
                    Toggle(isOn: Binding(
                        get: { appViewModel.isPreferenceOn(preference) },
                        set: { appViewModel.setPreference(preference, isOn: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preference.label)
                                .font(.body.weight(.medium))
                            Text(preference.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color.brandGreen)
                    .padding(.vertical, 10)

                    if preference.id != DietaryPreference.all.last?.id {
                        Divider()
                    }
                }
            }
        }
        .card()
    }

    // MARK: - Allergies

    private var allergiesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Allergies", systemImage: "exclamationmark.shield.fill", color: .allergyRed)
                Spacer()
                if !appViewModel.allergens.isEmpty {
                    Button("Clear All") {
                        showClearConfirm = true
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.allergyRed)
                }
            }

            Text("Tap everything you're allergic to.")
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(Allergen.common, id: \.self) { name in
                    allergenChip(name, isSelected: appViewModel.isAllergenSelected(name)) {
                        withAnimation(.snappy(duration: 0.2)) {
                            appViewModel.toggleAllergen(name)
                        }
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
            }

            if !appViewModel.customAllergens.isEmpty {
                Text("Your own")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                FlowLayout(spacing: 8) {
                    ForEach(appViewModel.customAllergens, id: \.self) { name in
                        customChip(name)
                    }
                }
            }

            HStack(spacing: 10) {
                TextField("Add another, e.g. Kiwi", text: $newAllergen)
                    .focused($isInputFocused)
                    .submitLabel(.done)
                    .onSubmit(addNewAllergen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.fieldBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button(action: addNewAllergen) {
                    Image(systemName: "plus")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .background(Color.allergyRed.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(newAllergen.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newAllergen.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                .accessibilityLabel("Add allergy")
            }
            .padding(.top, 4)
        }
        .card()
    }

    private func allergenChip(_ name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                }
                Text(name)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                Capsule().fill(isSelected ? Color.allergyRed : Color.fieldBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func customChip(_ name: String) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.subheadline.weight(.medium))
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    appViewModel.removeAllergens([name])
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(name)")
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .padding(.vertical, 8)
        .foregroundStyle(Color.white)
        .background(Capsule().fill(Color.allergyRed))
    }

    // MARK: - Shared bits

    private func sectionTitle(_ title: String, systemImage: String, color: Color) -> some View {
        Label {
            Text(title)
                .font(.headline)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(color)
        }
    }

    private var disclaimer: some View {
        Label {
            Text("Recipes are generated by AI and may still contain mistakes. Always check ingredient labels if you have a serious allergy.")
        } icon: {
            Image(systemName: "exclamationmark.shield")
                .foregroundStyle(.orange)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    private func addNewAllergen() {
        guard !newAllergen.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        // Added, or already in the list – either way clear the field and hide the keyboard.
        withAnimation(.snappy(duration: 0.2)) {
            _ = appViewModel.addCustomAllergen(newAllergen)
        }
        newAllergen = ""
        isInputFocused = false
    }
}

#Preview {
    UsersView()
        .environmentObject(AppViewModel())
}
