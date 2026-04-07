//
//  FruitCardView.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//

import SwiftUI

struct FruitCardView: View {
    let fruit: Fruit
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: isSelected
                        ? [Color.green.opacity(0.8), Color.green.opacity(0.3)]
                        : [Color(.systemGray6)]
                        ,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)

            VStack(spacing: 8) {
                Image(fruit.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(fruit.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(8)
        }
    }
}
