// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import NetworkError

final class PushNotificationsRepository: PushNotificationsRepositoryAPI {

    // MARK: - Properties

    private let apiClient: PushNotificationsClientAPI
    private let credentialsRepository: CredentialsRepositoryAPI

    // MARK: - Setup

    init(
        apiClient: PushNotificationsClientAPI = resolve(),
        credentialsRepository: CredentialsRepositoryAPI = resolve()
    ) {
        self.apiClient = apiClient
        self.credentialsRepository = credentialsRepository
    }

    // MARK: - API

    func revokeToken() -> AnyPublisher<Void, PushNotificationsRepositoryError> {
        Publishers.Zip(
            credentialsRepository.guid,
            credentialsRepository.sharedKey
        )
        .setFailureType(to: PushNotificationsRepositoryError.self)
        .flatMap { [apiClient] guidOrNil, sharedKeyOrNil -> AnyPublisher<Void, PushNotificationsRepositoryError> in
            guard let guid = guidOrNil else {
                return .failure(.missingCredentials(.guid))
            }
            guard let sharedKey = sharedKeyOrNil else {
                return .failure(.missingCredentials(.sharedKey))
            }
            return apiClient.revokeToken(guid: guid, sharedKey: sharedKey)
                .mapError(PushNotificationsRepositoryError.networkError)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
