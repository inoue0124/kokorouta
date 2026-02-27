import SwiftUI

struct CategoryChip: View {
    let category: WorryCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.appBody(size: 14))
                .foregroundStyle(isSelected ? Color.white : Color.appText)
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
    }
}

#Preview {
    HStack {
        CategoryChip(category: .relationship, isSelected: true) {}
        CategoryChip(category: .love, isSelected: false) {}
    }
    .padding()
}
