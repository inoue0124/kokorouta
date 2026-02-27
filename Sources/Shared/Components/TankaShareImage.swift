import SwiftUI

struct TankaShareImage: View {
    let tanka: Tanka

    var body: some View {
        ZStack {
            // 和紙風の暖かいグラデーション背景
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.94, blue: 0.90),
                    Color(red: 0.98, green: 0.96, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // カテゴリラベル（上部）
                Text(tanka.category.displayName)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color(red: 0.5, green: 0.48, blue: 0.45))
                    .padding(.top, 80)

                Spacer()

                // 縦書き短歌テキスト（中央）
                VerticalText(
                    text: tanka.tankaText,
                    fontSize: 48
                )

                Spacer()

                // ウォーターマーク（右下）
                HStack {
                    Spacer()
                    Text("こころうた")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Color(red: 0.7, green: 0.68, blue: 0.65))
                }
                .padding(.bottom, 60)
                .padding(.trailing, 60)
            }
        }
        .frame(width: 1080, height: 1080)
    }
}
