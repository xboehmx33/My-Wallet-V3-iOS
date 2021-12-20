// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import WalletPayloadKit

public final class GuidService: GuidServiceAPI {

    // MARK: - Properties

    /// Fetches the `GUID`
    public let guid: AnyPublisher<String, GuidServiceError>

    private let sessionTokenRepository: SessionTokenRepositoryAPI
    private let client: GuidClientAPI

    // MARK: - Setup

    public init(
        sessionTokenRepository: SessionTokenRepositoryAPI,
        client: GuidClientAPI
    ) {
        self.sessionTokenRepository = sessionTokenRepository
        self.client = client

        guid = sessionTokenRepository
            .sessionToken
            .flatMap { [client] token -> AnyPublisher<String?, GuidServiceError> in
                guard let token = token else {
                    return .failure(.missingSessionToken)
                }
                return client.guid(by: token)
                    .mapError(GuidServiceError.networkError)
                    .eraseToAnyPublisher()
            }
            .flatMap { guidOrNil -> AnyPublisher<String, GuidServiceError> in
                guard let guid = guidOrNil else {
                    return .failure(.missingGuid)
                }
                return .just(guid)
            }
            .share()
            .eraseToAnyPublisher()
    }
}
