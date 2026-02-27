import SwiftUI

struct VerticalText: View {
    let text: String
    var fontSize: CGFloat = 22

    var body: some View {
        let characters = Array(text)

        HStack(alignment: .top, spacing: fontSize * 0.8) {
            ForEach(lines(from: characters).indices, id: \.self) { lineIndex in
                let line = lines(from: characters)[lineIndex]
                VStack(spacing: fontSize * 0.2) {
                    ForEach(line.indices, id: \.self) { charIndex in
                        Text(String(line[charIndex]))
                            .font(.tankaFont(size: fontSize))
                            .foregroundStyle(Color.appText)
                    }
                }
            }
        }
    }

    /// 短歌テキストを行に分割する（右から左に表示するため reversed）
    private func lines(from characters: [Character]) -> [[Character]] {
        let text = String(characters)
        let segments = text.components(separatedBy: "\n")
            .flatMap { $0.components(separatedBy: "　") }
            .filter { !$0.isEmpty }

        return segments.reversed().map { Array($0) }
    }
}

#Preview {
    VerticalText(text: "秋の夜の\n長き思ひを\n短歌にて\n詠みて心の\n重荷おろさむ")
        .padding(40)
        .background(Color.white)
}
