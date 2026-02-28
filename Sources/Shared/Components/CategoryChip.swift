import SwiftUI

struct CategoryChip: View {
    let category: WorryCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.appBody(size: 14))
                .foregroundStyle(isSelected ? Color.appBackground : Color.appText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.appText : .clear,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(Color.appDivider, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.displayName)
        .accessibilityValue(isSelected ? "選択中" : "未選択")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    HStack {
        CategoryChip(category: .relationship, isSelected: true) {}
        CategoryChip(category: .love, isSelected: false) {}
    }
    .padding()
}
