#if DEBUG
    import Foundation

    final class PreviewTankaRepository: TankaRepositoryProtocol, @unchecked Sendable {
        private var tankaList: [Tanka]
        private var likedIDs: Set<String> = []
        private var blockedUserIDs: Set<String> = []

        init() {
            tankaList = Self.sampleTanka
        }

        func generateTanka(category: WorryCategory, worryText: String) async throws -> Tanka {
            try await Task.sleep(for: .seconds(2))
            let tankaTexts: [WorryCategory: String] = [
                .relationship: "人の世の\n絆ほどける\n夕暮れに\nひとつ結びし\n糸のあたたか",
                .love: "春風に\n揺れる花びら\n手のひらに\n受けて知りたる\n恋のはじまり",
                .work: "朝霧の\n晴れゆく空に\n光さし\n歩む一歩が\n道をつくらむ",
                .health: "雨上がり\n虹のかけ橋\n渡るごと\n明日を信じて\n深く息する",
            ]
            let tanka = Tanka(
                id: UUID().uuidString,
                authorID: "me",
                category: category,
                worryText: worryText,
                tankaText: tankaTexts[category] ?? tankaTexts[.work]!,
                likeCount: 0,
                isLikedByMe: false,
                createdAt: Date()
            )
            tankaList.insert(tanka, at: 0)
            return tanka
        }

        func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse {
            try await Task.sleep(for: .milliseconds(500))
            let filtered = tankaList.filter { !blockedUserIDs.contains($0.authorID) }
            if let afterID, let index = filtered.firstIndex(where: { $0.id == afterID }) {
                let start = filtered.index(after: index)
                let end = min(start + limit, filtered.endIndex)
                guard start < filtered.endIndex else {
                    return FeedResponse(tankaList: [], hasMore: false, nextCursor: nil)
                }
                let slice = Array(filtered[start ..< end])
                return FeedResponse(
                    tankaList: slice,
                    hasMore: end < filtered.endIndex,
                    nextCursor: slice.last?.id
                )
            }
            let end = min(limit, filtered.count)
            let slice = Array(filtered[0 ..< end])
            return FeedResponse(
                tankaList: slice,
                hasMore: end < filtered.count,
                nextCursor: slice.last?.id
            )
        }

        func fetchMyTanka() async throws -> [Tanka] {
            try await Task.sleep(for: .milliseconds(300))
            return tankaList.filter { $0.authorID == "me" }
        }

        func like(tankaID: String) async throws -> LikeResponse {
            likedIDs.insert(tankaID)
            if let index = tankaList.firstIndex(where: { $0.id == tankaID }) {
                tankaList[index].likeCount += 1
                tankaList[index].isLikedByMe = true
                return LikeResponse(likeCount: tankaList[index].likeCount)
            }
            return LikeResponse(likeCount: 1)
        }

        func unlike(tankaID: String) async throws -> LikeResponse {
            likedIDs.remove(tankaID)
            if let index = tankaList.firstIndex(where: { $0.id == tankaID }) {
                tankaList[index].likeCount = max(0, tankaList[index].likeCount - 1)
                tankaList[index].isLikedByMe = false
                return LikeResponse(likeCount: tankaList[index].likeCount)
            }
            return LikeResponse(likeCount: 0)
        }

        func report(tankaID: String, reason: ReportReason) async throws {
            tankaList.removeAll { $0.id == tankaID }
        }

        func blockUser(userID: String) async throws {
            blockedUserIDs.insert(userID)
        }

        func unblockUser(userID: String) async throws {
            blockedUserIDs.remove(userID)
        }

        func fetchBlockedUsers() async throws -> [BlockedUser] {
            blockedUserIDs.map { id in
                BlockedUser(id: UUID().uuidString, blockedID: id, createdAt: Date())
            }
        }

        func deleteAccount() async throws {
            tankaList.removeAll()
        }

        // MARK: - Sample Data

        private static let sampleTanka: [Tanka] = [
            Tanka(
                id: "1",
                authorID: "user-a",
                category: .work,
                worryText: "仕事がうまくいかなくて、毎日が辛いです。自分に自信が持てません。",
                tankaText: "朝霧の\n晴れゆく空に\n光さし\n歩む一歩が\n道をつくらむ",
                likeCount: 12,
                isLikedByMe: false,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Tanka(
                id: "2",
                authorID: "user-b",
                category: .love,
                worryText: "好きな人に気持ちを伝えられません。いつも言葉が出てこなくて。",
                tankaText: "春風に\n揺れる花びら\n手のひらに\n受けて知りたる\n恋のはじまり",
                likeCount: 8,
                isLikedByMe: true,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            Tanka(
                id: "3",
                authorID: "user-c",
                category: .relationship,
                worryText: "友人との関係がぎくしゃくしています。どうすれば元に戻れるでしょうか。",
                tankaText: "人の世の\n絆ほどける\n夕暮れに\nひとつ結びし\n糸のあたたか",
                likeCount: 5,
                isLikedByMe: false,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            Tanka(
                id: "4",
                authorID: "me",
                category: .health,
                worryText: "体調を崩しがちで、将来が不安です。健康でいるためにはどうすれば。",
                tankaText: "雨上がり\n虹のかけ橋\n渡るごと\n明日を信じて\n深く息する",
                likeCount: 3,
                isLikedByMe: false,
                createdAt: Date().addingTimeInterval(-172_800)
            ),
            Tanka(
                id: "5",
                authorID: "user-d",
                category: .work,
                worryText: "転職すべきか悩んでいます。今の職場に未来があるのか分かりません。",
                tankaText: "道ふたつ\n分かれし先の\n霧の中\n信じて踏み出す\n足もとの音",
                likeCount: 15,
                isLikedByMe: false,
                createdAt: Date().addingTimeInterval(-259_200)
            ),
            Tanka(
                id: "6",
                authorID: "user-e",
                category: .love,
                worryText: "長く付き合った恋人と別れました。立ち直れる気がしません。",
                tankaText: "散る桜\n惜しむ心に\n風吹きて\n新たな蕾\nもう芽吹きをり",
                likeCount: 22,
                isLikedByMe: false,
                createdAt: Date().addingTimeInterval(-345_600)
            ),
        ]
    }
#endif
