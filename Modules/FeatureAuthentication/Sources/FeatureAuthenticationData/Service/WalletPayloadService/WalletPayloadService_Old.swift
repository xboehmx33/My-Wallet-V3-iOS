// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import ToolKit
import WalletPayloadKit

public final class WalletPayloadServiceOld: WalletPayloadServiceAPI {
    // MARK: - Types

    typealias WalletRepositoryAPI = GuidRepositoryAPI &
        SessionTokenRepositoryAPI &
        SharedKeyRepositoryAPI &
        LanguageRepositoryAPI &
        SyncPubKeysRepositoryAPI &
        AuthenticatorRepositoryAPI &
        PayloadRepositoryAPI

    // MARK: - Properties

    private let client: WalletPayloadClientAPI
    private let repository: WalletRepositoryAPI

    // MARK: - Setup

    init(
        client: WalletPayloadClientAPI = WalletPayloadClient(),
        repository: WalletRepositoryAPI
    ) {
        self.client = client
        self.repository = repository
    }

    public func requestUsingSessionToken() -> AnyPublisher<WalletAuthenticatorType, WalletPayloadServiceError> {
        let request = request(guid:sessionToken:)
        return repository.guid
            .zip(repository.sessionToken)
            .flatMap { credentials -> AnyPublisher<(guid: String, sessionToken: String), WalletPayloadServiceError> in
                guard let guid = credentials.0 else {
                    return .failure(.missingCredentials(.guid))
                }
                guard let sessionToken = credentials.1 else {
                    return .failure(.missingCredentials(.sessionToken))
                }
                return .just((guid, sessionToken))
            }
            .flatMap { credentials -> AnyPublisher<WalletAuthenticatorType, WalletPayloadServiceError> in
                request(credentials.guid, credentials.sessionToken)
            }
            .eraseToAnyPublisher()
    }

    public func requestUsingSharedKey() -> AnyPublisher<Void, WalletPayloadServiceError> {
        let request = request(guid:sharedKey:)
        return repository.guid
            .zip(repository.sharedKey)
            .flatMap { credentials -> AnyPublisher<(guid: String, sharedKey: String), WalletPayloadServiceError> in
                guard let guid = credentials.0 else {
                    return .failure(.missingCredentials(.guid))
                }
                guard let sharedKey = credentials.1 else {
                    return .failure(.missingCredentials(.sharedKey))
                }
                return .just((guid, sharedKey))
            }
            .flatMap { credentials -> AnyPublisher<Void, WalletPayloadServiceError> in
                request(credentials.guid, credentials.sharedKey)
            }
            .eraseToAnyPublisher()
    }

    public func request(
        guid: String,
        sharedKey: String
    ) -> AnyPublisher<Void, WalletPayloadServiceError> {
        let cacheWalletData = cacheWalletData(from:)
        return client
            .payload(guid: guid, identifier: .sharedKey(sharedKey))
            .mapError(WalletPayloadServiceError.init)
            .flatMap { response -> AnyPublisher<Void, WalletPayloadServiceError> in
                cacheWalletData(response)
                    .mapToVoid()
            }
            .eraseToAnyPublisher()
    }

    public func request(
        guid: String,
        sessionToken: String
    ) -> AnyPublisher<WalletAuthenticatorType, WalletPayloadServiceError> {
        let cacheWalletData = cacheWalletData(from:)
        return client
            .payload(guid: guid, identifier: .sessionToken(sessionToken))
            .mapError(WalletPayloadServiceError.init)
            .flatMap { response -> AnyPublisher<WalletPayloadClient.ClientResponse, WalletPayloadServiceError> in
                cacheWalletData(response)
            }
            .flatMap { response -> AnyPublisher<WalletAuthenticatorType, WalletPayloadServiceError> in
                guard let type = WalletAuthenticatorType(rawValue: response.authType) else {
                    return .failure(.unsupported2FAType)
                }
                return .just(type)
            }
            .catch { error -> AnyPublisher<WalletAuthenticatorType, WalletPayloadServiceError> in
                switch error {
                case .emailAuthorizationRequired:
                    return .just(.email)
                default:
                    return .failure(error)
                }
            }
            .eraseToAnyPublisher()
    }

    func cacheWalletData(
        from clientResponse: WalletPayloadClient.ClientResponse
    ) -> AnyPublisher<WalletPayloadClient.ClientResponse, WalletPayloadServiceError> {
        repository.set(guid: clientResponse.guid)
            .zip(repository.set(language: clientResponse.language))
            .zip(repository.set(syncPubKeys: clientResponse.shouldSyncPubkeys))
            .flatMap { [repository] _ -> AnyPublisher<Void, WalletPayloadServiceError> in
                guard let type = WalletAuthenticatorType(rawValue: clientResponse.authType) else {
                    return .failure(.unsupported2FAType)
                }
                return repository.set(authenticatorType: type)
                    .mapError()
            }
            .flatMap { [repository] _ -> AnyPublisher<Void, WalletPayloadServiceError> in
                if let rawPayload = clientResponse.payload?.stringRepresentation, !rawPayload.isEmpty {
                    return repository.set(payload: rawPayload)
                        .mapError()
                }
                return .just(())
            }
            .flatMap { _ -> AnyPublisher<WalletPayloadClient.ClientResponse, WalletPayloadServiceError> in
                .just(clientResponse)
            }
            .eraseToAnyPublisher()
    }
}
