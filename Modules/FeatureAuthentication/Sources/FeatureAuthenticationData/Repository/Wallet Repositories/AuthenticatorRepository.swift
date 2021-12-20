// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import WalletPayloadKit

final class AuthenticatorRepository: AuthenticatorRepositoryAPI {
    let authenticatorType: AnyPublisher<WalletAuthenticatorType, Never>

    // This is set to the older WalletRepository API, soon to be removed
    private let walletRepository: WalletRepositoryAPI
    private let walletRepo: WalletRepo
    private let nativeWalletEnabled: () -> AnyPublisher<Bool, Never>

    init(
        walletRepository: WalletRepositoryAPI,
        walletRepo: WalletRepo,
        nativeWalletEnabled: @escaping () -> AnyPublisher<Bool, Never>
    ) {
        self.walletRepository = walletRepository
        self.walletRepo = walletRepo
        self.nativeWalletEnabled = nativeWalletEnabled

        authenticatorType = nativeWalletEnabled()
            .flatMap { isEnabled -> AnyPublisher<WalletAuthenticatorType, Never> in
                guard isEnabled else {
                    return walletRepository.authenticatorType
                }
                return walletRepo.map(\.properties.authenticatorType)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func set(authenticatorType: WalletAuthenticatorType) -> AnyPublisher<Void, Never> {
        nativeWalletEnabled()
            .flatMap { [walletRepo, walletRepository] isEnabled -> AnyPublisher<Void, Never> in
                guard isEnabled else {
                    return walletRepository.set(authenticatorType: authenticatorType)
                }
                return walletRepo.set(keyPath: \.properties.authenticatorType, value: authenticatorType)
                    .mapToVoid()
            }
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
