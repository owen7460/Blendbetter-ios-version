//
//  BlendingLoadingView.swift
//  BlendBetter
//

import SwiftUI

/// Bouncing fruit animation shown while a recipe is being generated.
struct BlendingLoadingView: View {
    let fruits: [String]
    /// Shown when there are no fruits to animate.
    let fallbackEmoji: String

    var body: some View {
        VStack(spacing: 14) {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate

                HStack(spacing: 16) {
                    if fruits.isEmpty {
                        bubble(index: 0, time: t) {
                            Text(fallbackEmoji).font(.system(size: 34))
                        }
                    } else {
                        ForEach(Array(fruits.enumerated()), id: \.offset) { index, name in
                            bubble(index: index, time: t) {
                                fruitTile(name)
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
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generating recipe")
    }

    @ViewBuilder
    private func fruitTile(_ name: String) -> some View {
        if let imageName = Fruit.named(name)?.imageName {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            FruitInitialView(name: name)
        }
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
    BlendingLoadingView(fruits: ["Banana", "Lychee", "Kiwi"], fallbackEmoji: "🥤")
        .padding()
}
