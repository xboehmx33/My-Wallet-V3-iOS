import Combine
import PlatformKit
import ToolKit

final class MockNabuUserService: NabuUserServiceAPI {

    struct StubbedResults {
        var user: AnyPublisher<NabuUser, NabuUserServiceError> = .empty()
        var fetchUser: AnyPublisher<NabuUser, NabuUserServiceError> = .empty()
        var setInitialResidentialInfo: AnyPublisher<Void, NabuUserServiceError> = .empty()
    }

    var stubbedResults = StubbedResults()

    var user: AnyPublisher<NabuUser, NabuUserServiceError> {
        stubbedResults.user
    }

    func fetchUser() -> AnyPublisher<NabuUser, NabuUserServiceError> {
        stubbedResults.fetchUser
    }

    func setInitialResidentialInfo(
        country: String,
        state: String?
    ) -> AnyPublisher<Void, NabuUserServiceError> {
        stubbedResults.setInitialResidentialInfo
    }
}
