import SwiftUI

struct ShareButton: View {
    let tanka: Tanka

    @State private var shareableImage: ShareableImage?
    @State private var showError = false

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
        .sheet(item: $shareableImage) { item in
            ShareSheet(items: [item.image])
        }
        .accessibilityLabel("共有")
        .accessibilityHint("短歌を画像として共有します")
        .alert("画像の生成に失敗しました", isPresented: $showError) {
            Button("OK") {}
        }
    }

    @MainActor
    private func generateAndShare() {
        let renderer = ImageRenderer(content: TankaShareImage(tanka: tanka))
        renderer.proposedSize = ProposedViewSize(width: 1080, height: 1080)
        renderer.scale = 1.0
        if let image = renderer.uiImage {
            shareableImage = ShareableImage(image: image)
        } else {
            showError = true
        }
    }
}

private struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
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
