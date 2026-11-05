//
//  BlendingLoadingView.swift
//  BlendBetter
//

import SwiftUI

/// Bouncing fruit animation shown while a recipe is being generated.
struct BlendingLoadingView: View {
    let fruits: [String]
    /// Shown when none of the fruits has an image (e.g. a camera-detected fruit).
    let fallbackEmoji: String

    private var imageNames: [String] {
        fruits.compactMap { name in
            Fruit.all.first { $0.name == name }?.imageName
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate

                HStack(spacing: 16) {
                    if imageNames.isEmpty {
                        bubble(index: 0, time: t) {
                            Text(fallbackEmoji).font(.system(size: 34))
                        }
                    } else {
                        ForEach(Array(imageNames.enumerated()), id: \.offset) { index, imageName in
                            bubble(index: index, time: t) {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
            }
            .frame(height: 80)

            HStack(spacing: 8) {
                ProgressView()
                Text("Blending your recipe…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generating recipe")
    }

    /// Each fruit hops in turn, slightly offset from the previous one.
    private func bubble<Content: View>(
        index: Int,
        time: TimeInterval,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let phase = time * 5 - Double(index) * 0.9
        let hop = max(0, sin(phase))

        return content()
            .offset(y: -hop * 18)
            .rotationEffect(.degrees(sin(phase) * 10))
            .scaleEffect(1 + hop * 0.08)
            .shadow(color: .black.opacity(0.12 * (1 - hop)), radius: 4, y: 3)
    }
}

#Preview {
    BlendingLoadingView(fruits: ["Banana", "Mango", "Kiwi"], fallbackEmoji: "🥤")
        .padding()
}
