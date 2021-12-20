// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain

class MockGuidSharedKeyRepositoryAPI: GuidRepositoryAPI, SharedKeyRepositoryAPI {

    var expectedGuid: String? = "123-abc-456-def-789-ghi"
    var expectedSharedKey: String? = "0123456789"

    var guid: AnyPublisher<String?, Never> {
        .just(expectedGuid)
    }

    var hasGuid: AnyPublisher<Bool, Never> {
        guid.map { $0 != nil }.eraseToAnyPublisher()
    }

    var sharedKey: AnyPublisher<String?, Never> {
        .just(expectedSharedKey)
    }

    func set(guid: String) -> AnyPublisher<Void, Never> {
        expectedGuid = guid
        return .just(())
    }

    func set(sharedKey: String) -> AnyPublisher<Void, Never> {
        expectedSharedKey = sharedKey
        return .just(())
    }
}
