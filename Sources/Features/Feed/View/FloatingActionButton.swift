import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil.line")
                .font(.system(size: 22))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(Color.appText, in: Circle())
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {}
                    .padding(24)
            }
        }
    }
}
