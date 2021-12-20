// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import WalletPayloadKit

public final class TwoFAWalletService: TwoFAWalletServiceAPI {

    // MARK: - Type

    public typealias WalletRepositoryAPI = GuidRepositoryAPI & SessionTokenRepositoryAPI & PayloadRepositoryAPI

    // MARK: - Properties

    private let client: TwoFAWalletClientAPI
    private let repository: WalletRepositoryAPI
    private let walletRepo: WalletRepo
    private let nativeWalletFlagEnabled: () -> AnyPublisher<Bool, Never>

    // MARK: - Setup

    public init(
        client: TwoFAWalletClientAPI,
        repository: WalletRepositoryAPI,
        walletRepo: WalletRepo,
        nativeWalletFlagEnabled: @escaping () -> AnyPublisher<Bool, Never>
    ) {
        self.client = client
        self.repository = repository
        self.walletRepo = walletRepo
        self.nativeWalletFlagEnabled = nativeWalletFlagEnabled
    }

    // MARK: - API

    public func send(code: String) -> AnyPublisher<Void, TwoFAWalletServiceError> {
        // Trim whitespaces before verifying and sending
        let code = code.trimmingWhitespaces

        // Verify the code is not empty to save network call
        guard !code.isEmpty else {
            return .failure(.missingCode)
        }

        return nativeWalletFlagEnabled()
            .flatMap { [old_send, new_send] isEnabled -> AnyPublisher<Void, TwoFAWalletServiceError> in
                guard isEnabled else {
                    return old_send(code)
                }
                return new_send(code)
            }
            .eraseToAnyPublisher()
    }

    private func old_send(code: String) -> AnyPublisher<Void, TwoFAWalletServiceError> {
        repository.guid
            .zip(repository.sessionToken)
            .flatMap { credentials -> AnyPublisher<(guid: String, sessionToken: String), TwoFAWalletServiceError> in
                guard let guid = credentials.0 else {
                    return .failure(.missingCredentials(.guid))
                }
                guard let sessionToken = credentials.1 else {
                    return .failure(.missingCredentials(.sessionToken))
                }
                return .just((guid, sessionToken))
            }
            .flatMap { [client] credentials -> AnyPublisher<WalletPayloadWrapper, TwoFAWalletServiceError> in
                client.payload(
                    guid: credentials.guid,
                    sessionToken: credentials.sessionToken,
                    code: code
                )
                .mapError { error in
                    switch error {
                    case .wrongCode(attemptsLeft: let attemptsLeft):
                        return .wrongCode(attemptsLeft: attemptsLeft)
                    case .accountLocked:
                        return .accountLocked
                    case .networkError(let error):
                        return .networkError(error)
                    }
                }
                .eraseToAnyPublisher()
            }
            .flatMap { response -> AnyPublisher<String, TwoFAWalletServiceError> in
                guard let rawPayload = response.stringRepresentation, !rawPayload.isEmpty else {
                    return .failure(.missingPayload)
                }
                return .just(rawPayload)
            }
            .flatMap { [repository] rawPayload -> AnyPublisher<Void, TwoFAWalletServiceError> in
                repository.set(payload: rawPayload)
                    .mapError()
            }
            .eraseToAnyPublisher()
    }

    private func new_send(code: String) -> AnyPublisher<Void, TwoFAWalletServiceError> {
        walletRepo.credentials
            .first()
            .flatMap { credentials -> AnyPublisher<(guid: String, sessionToken: String), TwoFAWalletServiceError> in
                guard !credentials.guid.isEmpty else {
                    return .failure(.missingCredentials(.guid))
                }
                guard !credentials.sessionToken.isEmpty else {
                    return .failure(.missingCredentials(.sessionToken))
                }
                return .just((credentials.guid, credentials.sessionToken))
            }
            .flatMap { [client] credentials -> AnyPublisher<WalletPayloadWrapper, TwoFAWalletServiceError> in
                client.payload(
                    guid: credentials.guid,
                    sessionToken: credentials.sessionToken,
                    code: code
                )
                .mapError { error in
                    switch error {
                    case .wrongCode(attemptsLeft: let attemptsLeft):
                        return .wrongCode(attemptsLeft: attemptsLeft)
                    case .accountLocked:
                        return .accountLocked
                    case .networkError(let error):
                        return .networkError(error)
                    }
                }
                .eraseToAnyPublisher()
            }
            .flatMap { [walletRepo] rawPayload -> AnyPublisher<Void, TwoFAWalletServiceError> in
                walletRepo.set(keyPath: \.encryptedPayload, value: rawPayload)
                    .mapToVoid()
                    .mapError()
            }
            .eraseToAnyPublisher()
    }
}
