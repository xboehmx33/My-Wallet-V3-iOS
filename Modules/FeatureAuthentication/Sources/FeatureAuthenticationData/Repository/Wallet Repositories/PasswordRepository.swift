// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import WalletPayloadKit

final class PasswordRepository: PasswordRepositoryAPI {
    let hasPassword: AnyPublisher<Bool, Never>
    let password: AnyPublisher<String?, Never>

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

        password = nativeWalletEnabled()
            .flatMap { isEnabled -> AnyPublisher<String?, Never> in
                guard isEnabled else {
                    return walletRepository.password
                }
                return walletRepo.map(\.credentials.password)
                    .map { key in key.isEmpty ? nil : key }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()

        hasPassword = nativeWalletEnabled()
            .flatMap { isEnabled -> AnyPublisher<Bool, Never> in
                guard isEnabled else {
                    return walletRepository.hasPassword
                }
                return walletRepo.map(\.credentials.password)
                    .map { key in !key.isEmpty }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func set(password: String) -> AnyPublisher<Void, Never> {
        nativeWalletEnabled()
            .flatMap { [walletRepository, walletRepo] isEnabled -> AnyPublisher<Void, Never> in
                guard isEnabled else {
                    return walletRepository.set(password: password)
                }
                return walletRepo
                    .set(keyPath: \.credentials.password, value: password)
                    .mapToVoid()
                    .mapError()
            }
            .eraseToAnyPublisher()
    }

    #warning("TODO: NativeWallet should support syncing of password change")
    func sync() -> AnyPublisher<Void, PasswordRepositoryError> {
        walletRepository.sync()
    }
}
