import SwiftUI

struct AnimatedVerticalText: View {
    let text: String
    var fontSize: CGFloat = 22
    var font: Font?
    var phraseDelay: Double = 0.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visiblePhraseCount: Int = 0

    var body: some View {
        let phrases = buildPhrases()
        let reversed = Array(phrases.reversed())

        HStack(alignment: .top, spacing: fontSize * 0.8) {
            ForEach(reversed.indices, id: \.self) { index in
                let chars = Array(reversed[index])
                let displayOrder = reversed.count - 1 - index
                let isVisible = displayOrder < visiblePhraseCount

                VStack(spacing: fontSize * 0.2) {
                    ForEach(chars.indices, id: \.self) { charIndex in
                        let char = chars[charIndex]
                        Text(String(char))
                            .font(font ?? .tankaFont(size: fontSize))
                            .foregroundStyle(Color.appText)
                            .offset(
                                x: char.isVerticalPunctuation ? fontSize * 0.3 : 0,
                                y: char.isVerticalPunctuation ? -fontSize * 0.3 : 0
                            )
                    }
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(
                    reduceMotion
                        ? .none
                        : .easeOut(duration: 0.5).delay(Double(displayOrder) * phraseDelay),
                    value: visiblePhraseCount
                )
            }
        }
        .onAppear {
            visiblePhraseCount = buildPhrases().count
        }
    }

    private func buildPhrases() -> [String] {
        text.components(separatedBy: "\n")
            .flatMap { $0.components(separatedBy: "\u{3000}") }
            .flatMap { $0.components(separatedBy: " ") }
            .filter { !$0.isEmpty }
    }
}

private extension Character {
    var isVerticalPunctuation: Bool {
        self == "\u{3001}" || self == "\u{3002}" || self == "\u{FF0C}" || self == "\u{FF0E}"
    }
}

#Preview {
    AnimatedVerticalText(text: "秋の夜の\n長き思ひを\n短歌にて\n詠みて心の\n重荷おろさむ")
        .padding(40)
        .background(Color.appCardBackground)
}
