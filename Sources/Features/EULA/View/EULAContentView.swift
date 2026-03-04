import SwiftUI

struct EULAContentView: View {
    var body: some View {
        ScrollView {
            Text(EULAContent.fullText)
                .font(.appBody(size: 14))
                .foregroundStyle(Color.appText)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .background(Color.appBackground)
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EULAContentView()
    }
}
