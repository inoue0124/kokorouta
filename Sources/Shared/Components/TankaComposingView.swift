import SwiftUI

struct TankaComposingView: View {
    var message: String = "短歌を詠んでいます..."

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe: Bool = false

    private let rippleCount = 3
    private let cycleDuration: TimeInterval = 4
    private let inkColor = Color.appText.opacity(0.08)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                if reduceMotion {
                    staticIndicator
                } else {
                    rippleEffect
                }
            }
            .frame(width: 120, height: 120)

            Spacer()
                .frame(height: 32)

            Text(message)
                .font(.appCaption())
                .foregroundStyle(Color.appSubText)
                .opacity(reduceMotion ? 1 : (breathe ? 1 : 0.4))
                .animation(
                    reduceMotion ? .none : .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: breathe
                )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .onAppear {
            guard !reduceMotion else { return }
            breathe = true
        }
    }

    // MARK: - Ripple Animation

    private var rippleEffect: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let progress = now.remainder(dividingBy: cycleDuration) / cycleDuration + 0.5

            ZStack {
                ForEach(0 ..< rippleCount, id: \.self) { index in
                    let delay = Double(index) / Double(rippleCount)
                    let phase = (progress + delay).truncatingRemainder(dividingBy: 1.0)

                    Circle()
                        .stroke(inkColor, lineWidth: 1.5)
                        .scaleEffect(phase + 0.1)
                        .opacity(1 - phase)
                }

                Circle()
                    .fill(Color.appText.opacity(0.12))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Reduced Motion Fallback

    private var staticIndicator: some View {
        Circle()
            .stroke(inkColor, lineWidth: 1.5)
            .frame(width: 40, height: 40)
    }
}

#Preview {
    TankaComposingView()
}

#Preview("Reduced Motion") {
    // 実機のアクセシビリティ設定で確認
    TankaComposingView()
}
