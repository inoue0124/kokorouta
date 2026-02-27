@testable import App
import Foundation

extension Tanka {
    static func mock(
        id: String = "tanka-1",
        authorID: String = "author-1",
        category: WorryCategory = .work,
        worryText: String = "テスト悩み",
        tankaText: String = "秋の夜の\n長き思ひを\n短歌にて\n詠みて心の\n重荷おろさむ",
        likeCount: Int = 0,
        isLikedByMe: Bool = false,
        createdAt: Date = Date()
    ) -> Tanka {
        Tanka(
            id: id,
            authorID: authorID,
            category: category,
            worryText: worryText,
            tankaText: tankaText,
            likeCount: likeCount,
            isLikedByMe: isLikedByMe,
            createdAt: createdAt
        )
    }
}

extension BlockedUser {
    static func mock(
        id: String = "block-1",
        blockedID: String = "blocked-user-1",
        createdAt: Date = Date()
    ) -> BlockedUser {
        BlockedUser(id: id, blockedID: blockedID, createdAt: createdAt)
    }
}
