// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import ToolKit
import WalletPayloadKit

public final class WalletPayloadServiceNew: WalletPayloadServiceAPI {
    // MARK: - Properties

    private let client: WalletPayloadClientAPI
    private let walletRepo: WalletRepo

    init(
        client: WalletPayloadClientAPI,
        walletRepo: WalletRepo
    ) {
        self.client = client
        self.walletRepo = walletRepo
    }

    public func requestUsingSessionToken() -> AnyPublisher<WalletAuthenticatorType, WalletPayloadServiceError> {
        let request = request(guid:sessionToken:)
        return walletRepo.credentials
            .first()
            .flatMap { credentials -> AnyPublisher<(guid: String, sessionToken: String), WalletPayloadServiceError> in
                guard !credentials.guid.isEmpty else {
                    return .failure(.missingCredentials(.guid))
                }
                guard !credentials.sessionToken.isEmpty else {
                    return .failure(.missingCredentials(.sessionToken))
                }
                return .just((credentials.guid, credentials.sessionToken))
            }
            .flatMap { credentials -> AnyPublisher<WalletAuthenticatorType, WalletPayloadServiceError> in
                request(credentials.guid, credentials.sessionToken)
            }
            .eraseToAnyPublisher()
    }

    public func requestUsingSharedKey() -> AnyPublisher<Void, WalletPayloadServiceError> {
        let request = request(guid:sharedKey:)
        return walletRepo.credentials
            .first()
            .flatMap { credentials -> AnyPublisher<(guid: String, sharedKey: String), WalletPayloadServiceError> in
                guard !credentials.guid.isEmpty else {
                    return .failure(.missingCredentials(.guid))
                }
                guard !credentials.sharedKey.isEmpty else {
                    return .failure(.missingCredentials(.sharedKey))
                }
                return .just((credentials.guid, credentials.sharedKey))
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

    private func cacheWalletData(
        from clientResponse: WalletPayloadClient.ClientResponse
    ) -> AnyPublisher<WalletPayloadClient.ClientResponse, WalletPayloadServiceError> {
        guard let authenticatorType = WalletAuthenticatorType(rawValue: clientResponse.authType) else {
            return .failure(.unsupported2FAType)
        }
        guard let rawPayload = clientResponse.payload else {
            return .failure(.missingPayload)
        }
        return walletRepo
            .set(keyPath: \.credentials.guid, value: clientResponse.guid)
            .set(keyPath: \.properties.language, value: clientResponse.language)
            .set(keyPath: \.properties.syncPubKeys, value: clientResponse.shouldSyncPubkeys)
            .set(keyPath: \.encryptedPayload, value: rawPayload)
            .set(keyPath: \.properties.authenticatorType, value: authenticatorType)
            .map { _ in clientResponse }
            .first()
            .mapError()
    }
}
