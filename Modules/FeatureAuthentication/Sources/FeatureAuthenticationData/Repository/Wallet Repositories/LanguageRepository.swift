// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import WalletPayloadKit

final class LanguageRepository: LanguageRepositoryAPI {

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
    }

    func set(language: String) -> AnyPublisher<Void, Never> {
        nativeWalletEnabled()
            .flatMap { [walletRepository, walletRepo] isEnabled -> AnyPublisher<Void, Never> in
                guard isEnabled else {
                    return walletRepository.set(language: language)
                }
                return walletRepo.set(keyPath: \.properties.language, value: language)
                    .mapToVoid()
                    .mapError()
            }
            .eraseToAnyPublisher()
    }
}
