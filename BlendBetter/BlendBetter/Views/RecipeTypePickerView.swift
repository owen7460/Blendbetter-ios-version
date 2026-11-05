import SwiftUI

struct RecipeTypePickerView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(RecipeOption.options) { option in
                Button {
                    appViewModel.selectedRecipeOption = option
                    dismiss()
                } label: {
                    HStack {
                        Text("\(option.emoji) \(option.label)")
                        Spacer()
                        if option.id == appViewModel.selectedRecipeOption.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Recipe Type")
        }
    }
}
