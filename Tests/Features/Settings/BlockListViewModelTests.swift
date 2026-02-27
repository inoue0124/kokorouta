@testable import App
import Testing

@MainActor
struct BlockListViewModelTests {
    @Test
    func loadBlockedUsers_success_updatesBlockedUsers() async {
        let mock = MockTankaRepository()
        mock.stubbedBlockedUsers = [
            BlockedUser.mock(id: "b1", blockedID: "user-1"),
            BlockedUser.mock(id: "b2", blockedID: "user-2"),
        ]
        let viewModel = BlockListViewModel(tankaRepository: mock)

        await viewModel.loadBlockedUsers()

        #expect(viewModel.blockedUsers.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test
    func loadBlockedUsers_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = BlockListViewModel(tankaRepository: mock)

        await viewModel.loadBlockedUsers()

        #expect(viewModel.blockedUsers.isEmpty)
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test
    func loadBlockedUsers_empty_setsEmptyList() async {
        let mock = MockTankaRepository()
        mock.stubbedBlockedUsers = []
        let viewModel = BlockListViewModel(tankaRepository: mock)

        await viewModel.loadBlockedUsers()

        #expect(viewModel.blockedUsers.isEmpty)
        #expect(viewModel.error == nil)
    }

    @Test
    func unblock_success_removesUserFromList() async {
        let mock = MockTankaRepository()
        mock.stubbedBlockedUsers = [
            BlockedUser.mock(id: "b1", blockedID: "user-1"),
            BlockedUser.mock(id: "b2", blockedID: "user-2"),
        ]
        let viewModel = BlockListViewModel(tankaRepository: mock)
        await viewModel.loadBlockedUsers()

        await viewModel.unblock(userID: "user-1")

        #expect(viewModel.blockedUsers.count == 1)
        #expect(viewModel.blockedUsers[0].blockedID == "user-2")
        #expect(mock.unblockUserCallCount == 1)
        #expect(mock.unblockUserLastUserID == "user-1")
    }

    @Test
    func unblock_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedBlockedUsers = [BlockedUser.mock(blockedID: "user-1")]
        let viewModel = BlockListViewModel(tankaRepository: mock)
        await viewModel.loadBlockedUsers()
        mock.stubbedError = NetworkError.serverError(statusCode: 500)

        await viewModel.unblock(userID: "user-1")

        #expect(viewModel.error != nil)
        #expect(viewModel.blockedUsers.count == 1)
    }

    @Test
    func loadBlockedUsers_retry_clearsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = BlockListViewModel(tankaRepository: mock)
        await viewModel.loadBlockedUsers()
        #expect(viewModel.error != nil)

        mock.stubbedError = nil
        mock.stubbedBlockedUsers = [BlockedUser.mock(blockedID: "user-1")]
        await viewModel.loadBlockedUsers()

        #expect(viewModel.error == nil)
        #expect(viewModel.blockedUsers.count == 1)
    }

    @Test
    func unblock_multipleUsers_removesOnlyTargetUser() async {
        let mock = MockTankaRepository()
        mock.stubbedBlockedUsers = [
            BlockedUser.mock(id: "b1", blockedID: "user-1"),
            BlockedUser.mock(id: "b2", blockedID: "user-2"),
            BlockedUser.mock(id: "b3", blockedID: "user-3"),
        ]
        let viewModel = BlockListViewModel(tankaRepository: mock)
        await viewModel.loadBlockedUsers()

        await viewModel.unblock(userID: "user-2")

        #expect(viewModel.blockedUsers.count == 2)
        #expect(viewModel.blockedUsers.contains { $0.blockedID == "user-1" })
        #expect(!viewModel.blockedUsers.contains { $0.blockedID == "user-2" })
        #expect(viewModel.blockedUsers.contains { $0.blockedID == "user-3" })
    }

    @Test
    func initialState_hasCorrectDefaults() {
        let mock = MockTankaRepository()
        let viewModel = BlockListViewModel(tankaRepository: mock)

        #expect(viewModel.blockedUsers.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test
    func loadBlockedUsers_serverError_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.serverError(statusCode: 503)
        let viewModel = BlockListViewModel(tankaRepository: mock)

        await viewModel.loadBlockedUsers()

        #expect(viewModel.error != nil)
        #expect(viewModel.blockedUsers.isEmpty)
        #expect(viewModel.isLoading == false)
    }
}
