//
//  AIConsentView.swift
//  BlendBetter
//
//  Shown before the first recipe is generated (App Review Guideline 5.1.2(i):
//  disclose and get permission before sharing personal data with third-party AI).
//

import SwiftUI

struct AIConsentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 64, height: 64)
                    .background(Color.brandGreen.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Before we blend")
                        .font(.title2.weight(.bold))
                    Text("To write your recipe, BlendBetter sends the following to its server, which passes it to a third-party AI provider:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    item(
                        icon: "takeoutbag.and.cup.and.straw.fill",
                        color: .brandGreenDeep,
                        title: "Your fruits and drink type",
                        detail: "For example: Smoothie with mango and kiwi."
                    )
                    item(
                        icon: "exclamationmark.shield.fill",
                        color: .allergyRed,
                        title: "Your allergies",
                        detail: appViewModel.allergens.isEmpty
                            ? "None set right now."
                            : appViewModel.allergens.joined(separator: ", ")
                    )
                    item(
                        icon: "leaf.fill",
                        color: .brandGreenDeep,
                        title: "Your dietary preferences",
                        detail: appViewModel.activePreferences.isEmpty
                            ? "None set right now."
                            : appViewModel.activePreferences.map(\.label).joined(separator: ", ")
                    )
                }
                .card()

                Text("This is sent each time you tap Generate, and nothing is sent until you agree. You can turn this off anytime in the Allergies tab. Our Privacy Policy explains which AI provider we use and how your data is handled.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let url = AppLinks.privacyPolicyURL {
                    Link("Read our Privacy Policy", destination: url)
                        .font(.footnote.weight(.semibold))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button {
                    appViewModel.grantAIConsent()
                    dismiss()
                    appViewModel.startGeneration()
                } label: {
                    Text("Agree & Generate")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Not Now") {
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .background(Color.appBackground)
        }
        .presentationDragIndicator(.visible)
    }

    private func item(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AIConsentView()
        .environmentObject(AppViewModel())
}
