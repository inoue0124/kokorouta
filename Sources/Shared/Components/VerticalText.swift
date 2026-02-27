import SwiftUI

struct VerticalText: View {
    let text: String
    var fontSize: CGFloat = 22
    var font: Font?
    var maxCharsPerColumn: Int = 0

    var body: some View {
        let columns = buildColumns()

        HStack(alignment: .top, spacing: fontSize * 0.8) {
            ForEach(columns.indices, id: \.self) { columnIndex in
                let column = columns[columnIndex]
                VStack(spacing: fontSize * 0.2) {
                    ForEach(column.indices, id: \.self) { charIndex in
                        let char = column[charIndex]
                        Text(String(char))
                            .font(font ?? .tankaFont(size: fontSize))
                            .foregroundStyle(Color.appText)
                            .offset(
                                x: char.isVerticalPunctuation ? fontSize * 0.3 : 0,
                                y: char.isVerticalPunctuation ? -fontSize * 0.3 : 0
                            )
                    }
                }
            }
        }
    }

    private func buildColumns() -> [[Character]] {
        if maxCharsPerColumn > 0 {
            return wrapColumns(from: text, maxChars: maxCharsPerColumn)
        }
        return splitByNewlines(from: text)
    }

    /// 短歌テキストを行に分割する（右から左に表示するため reversed）
    private func splitByNewlines(from text: String) -> [[Character]] {
        let segments = text.components(separatedBy: "\n")
            .flatMap { $0.components(separatedBy: "　") }
            .filter { !$0.isEmpty }

        return segments.reversed().map { Array($0) }
    }

    /// 長文テキストを一定文字数で折り返して縦書き列にする（右から左）
    private func wrapColumns(from text: String, maxChars: Int) -> [[Character]] {
        let cleaned = text.replacingOccurrences(of: "\n", with: "")
        var columns: [[Character]] = []
        var current: [Character] = []

        for char in cleaned {
            current.append(char)
            if current.count >= maxChars {
                columns.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            columns.append(current)
        }

        return columns.reversed()
    }
}

private extension Character {
    var isVerticalPunctuation: Bool {
        self == "、" || self == "。" || self == "，" || self == "．"
    }
}

#Preview {
    VerticalText(text: "秋の夜の\n長き思ひを\n短歌にて\n詠みて心の\n重荷おろさむ")
        .padding(40)
        .background(Color.white)
}
