//
//  AIDisclaimer.swift
//  BlendBetter
//

import SwiftUI

/// Small grey note under every generated recipe.
/// Names the user's allergens when there are any, so the reminder is specific.
struct AIDisclaimer: View {
    var allergens: [String] = []

    var body: some View {
        Label {
            Text(message)
        } icon: {
            Image(systemName: "info.circle")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var message: String {
        let base = "BlendBetter can make mistakes."
        guard !allergens.isEmpty else {
            return base + " Double-check ingredients, especially if you have allergies."
        }
        let names = allergens.map { $0.lowercased() }
        let list: String
        if names.count <= 3 {
            list = names.count == 1
                ? names[0]
                : names.dropLast().joined(separator: ", ") + " and " + names[names.count - 1]
        } else {
            list = names.prefix(3).joined(separator: ", ") + " and your other allergens"
        }
        return base + " Always check labels for \(list)."
    }
}

#Preview {
    VStack(spacing: 20) {
        AIDisclaimer()
        AIDisclaimer(allergens: ["Peanuts", "Milk / dairy"])
    }
    .padding()
}
