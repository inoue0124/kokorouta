import SwiftUI

struct ShareButton: View {
    let tanka: Tanka

    @State private var shareImage: UIImage?
    @State private var isShowingShareSheet = false

    var body: some View {
        Button {
            generateAndShare()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                Text("シェア")
            }
            .font(.appCaption())
            .foregroundStyle(Color.appSubText)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    @MainActor
    private func generateAndShare() {
        let renderer = ImageRenderer(content: TankaShareImage(tanka: tanka))
        renderer.scale = 1.0
        if let image = renderer.uiImage {
            shareImage = image
            isShowingShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
