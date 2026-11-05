import SwiftUI

struct FruitCardView: View {
    let fruit: Fruit
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
                .frame(height: 100)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.green.opacity(0.8),
                                            Color.green.opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .blur(radius: 20)
                        }
                    }
                )

            Image(fruit.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
