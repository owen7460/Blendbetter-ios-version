//
//  SurpriseToast.swift
//  BlendBetter
//

import SwiftUI

/// Short banner that slides in after "Surprise me", e.g. "Surprise! Mango, Lychee & Lime".
struct SurpriseToast: View {
    let message: String

    private let green = Color(red: 0.48, green: 0.78, blue: 0.51)

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "dice.fill")
                .font(.title3)
                .foregroundStyle(green)
                .symbolEffect(.bounce, options: .repeat(2))

            Text(message)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(green.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    SurpriseToast(message: "Surprise! Mango, Lychee & Lime")
}
