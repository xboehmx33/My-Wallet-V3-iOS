// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import ToolKit
import WalletPayloadKit

public final class SMSService: SMSServiceAPI {

    // MARK: - Properties

    private let client: SMSClientAPI
    private let credentialsRepository: CredentialsRepositoryAPI
    private let sessionTokenRepository: SessionTokenRepositoryAPI

    public init(
        client: SMSClientAPI,
        credentialsRepository: CredentialsRepositoryAPI,
        sessionTokenRepository: SessionTokenRepositoryAPI
    ) {
        self.client = client
        self.credentialsRepository = credentialsRepository
        self.sessionTokenRepository = sessionTokenRepository
    }

    // MARK: - API

    public func request() -> AnyPublisher<Void, SMSServiceError> {
        credentialsRepository.guid
            .zip(sessionTokenRepository.sessionToken) {
                (guid: $0, sessionToken: $1)
            }
            .flatMap { credentials -> AnyPublisher<(guid: String, sessionToken: String), SMSServiceError> in
                guard let guid = credentials.guid else {
                    return .failure(.missingCredentials(.guid))
                }
                guard let sessionToken = credentials.sessionToken else {
                    return .failure(.missingCredentials(.sessionToken))
                }
                return .just((guid, sessionToken))
            }
            .flatMap { [client] credentials -> AnyPublisher<Void, SMSServiceError> in
                client.requestOTP(
                    sessionToken: credentials.sessionToken,
                    guid: credentials.guid
                )
                .mapError(SMSServiceError.networkError)
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
