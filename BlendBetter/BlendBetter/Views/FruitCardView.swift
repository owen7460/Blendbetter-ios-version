import SwiftUI

struct FruitCardView: View {
    let fruit: Fruit
    let isSelected: Bool
    /// True when the limit is reached and this fruit can't be added.
    var isDimmed: Bool = false

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

            Group {
                if let imageName = fruit.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    FruitInitialView(name: fruit.name)
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fruit.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isDimmed ? "Limit reached. Remove a fruit to choose this one." : "")
        .opacity(isDimmed ? 0.35 : 1)
        .saturation(isDimmed ? 0.3 : 1)
        .animation(.easeInOut(duration: 0.2), value: isDimmed)
    }
}

/// Placeholder for fruits without a picture: a soft colored tile with the initial.
struct FruitInitialView: View {
    let name: String

    private var color: Color {
        let palette: [Color] = [.orange, .pink, .purple, .red, .yellow, .green, .mint, .teal, .indigo]
        let index = name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % palette.count
        return palette[index]
    }

    var body: some View {
        ZStack {
            color.opacity(0.25)
            Text(String(name.prefix(1)))
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }
}
