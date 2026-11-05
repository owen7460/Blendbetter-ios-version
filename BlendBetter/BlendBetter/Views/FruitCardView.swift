import SwiftUI

struct FruitCardView: View {
    let fruit: Fruit
    let isSelected: Bool
    /// True when the limit is reached and this fruit can't be added.
    var isDimmed: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let imageName = fruit.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        FruitInitialView(name: fruit.name)
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.brandGreen)
                        .background(Circle().fill(Color.white).padding(3))
                        .offset(x: 8, y: -8)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Text(fruit.name)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isSelected ? Color.brandGreenDeep : Color.primary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? Color.brandGreen.opacity(0.16) : Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.brandGreen : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(isSelected ? 0 : 0.05), radius: 8, y: 3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fruit.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isDimmed ? "Limit reached. Remove a fruit to choose this one." : "")
        .opacity(isDimmed ? 0.6 : 1)
        .saturation(isDimmed ? 0.6 : 1)
        .animation(.spring(duration: 0.3), value: isSelected)
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
