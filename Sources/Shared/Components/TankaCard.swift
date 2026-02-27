import SwiftUI

struct TankaCard: View {
    let tanka: Tanka
    var onLike: (() -> Void)?
    var initialFlipped: Bool
    var useAnimatedBackFace: Bool

    @State private var isFlipped: Bool
    @State private var hasAnimatedOnce = false

    init(
        tanka: Tanka,
        onLike: (() -> Void)? = nil,
        initialFlipped: Bool = false,
        useAnimatedBackFace: Bool = false
    ) {
        self.tanka = tanka
        self.onLike = onLike
        self.initialFlipped = initialFlipped
        self.useAnimatedBackFace = useAnimatedBackFace
        _isFlipped = State(initialValue: initialFlipped)
    }

    var body: some View {
        ZStack {
            // 裏面: 縦書き短歌
            backFace
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )

            // 表面: 悩みテキスト
            frontFace
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.4)) {
                isFlipped.toggle()
            }
            if !hasAnimatedOnce {
                hasAnimatedOnce = true
            }
        }
    }

    private var frontAccessibilityLabel: String {
        "悩み: \(tanka.worryText)、カテゴリ: \(tanka.category.displayName)、\(tanka.createdAt.shortDisplayString)"
    }

    private var backAccessibilityLabel: String {
        "短歌: \(tanka.tankaText.replacingOccurrences(of: "\n", with: " "))、\(tanka.createdAt.shortDisplayString)"
    }

    // MARK: - Front Face

    private var frontFace: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                HStack {
                    Text(tanka.category.displayName)
                        .font(.appCaption())
                        .foregroundStyle(Color.appSubText)
                    Spacer()
                    Text(tanka.createdAt.shortDisplayString)
                        .font(.appCaption())
                        .foregroundStyle(Color.appSubText)
                }

                Spacer()

                VerticalText(
                    text: tanka.worryText,
                    fontSize: 16,
                    font: .appBody(),
                    maxCharsPerColumn: 12
                )

                Spacer()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(frontAccessibilityLabel)
            .accessibilityHint("タップして裏返す")
            .accessibilityAddTraits(.isButton)

            HStack {
                Spacer()
                if let onLike {
                    LikeButton(
                        isLiked: tanka.isLikedByMe,
                        count: tanka.likeCount,
                        action: onLike
                    )
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Back Face

    private var backFace: some View {
        VStack {
            VStack {
                Spacer()
                if useAnimatedBackFace, !hasAnimatedOnce {
                    AnimatedVerticalText(text: tanka.tankaText)
                } else {
                    VerticalText(text: tanka.tankaText)
                }
                Spacer()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(backAccessibilityLabel)
            .accessibilityHint("タップして裏返す")
            .accessibilityAddTraits(.isButton)

            HStack {
                Spacer()
                ShareButton(tanka: tanka)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(24)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

#Preview("Feed Card") {
    TankaCard(
        tanka: Tanka(
            id: "1",
            authorID: "author1",
            category: .work,
            worryText: "仕事がうまくいかなくて、毎日が辛いです。自分に自信が持てません。",
            tankaText: "朝霧の\n晴れゆく空に\n光さし\n歩む一歩が\n道をつくらむ",
            likeCount: 5,
            isLikedByMe: false,
            createdAt: Date()
        )
    ) {
        // preview
    }
    .padding(20)
    .background(Color.appBackground)
}

#Preview("Result Card") {
    TankaCard(
        tanka: Tanka(
            id: "1",
            authorID: "author1",
            category: .work,
            worryText: "仕事がうまくいかなくて、毎日が辛いです。自分に自信が持てません。",
            tankaText: "朝霧の\n晴れゆく空に\n光さし\n歩む一歩が\n道をつくらむ",
            likeCount: 0,
            isLikedByMe: false,
            createdAt: Date()
        ),
        initialFlipped: true,
        useAnimatedBackFace: true
    )
    .padding(20)
    .background(Color.appBackground)
}
