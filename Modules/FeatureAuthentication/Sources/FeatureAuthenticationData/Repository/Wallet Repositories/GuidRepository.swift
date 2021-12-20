// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import WalletPayloadKit

final class GuidRepository: GuidRepositoryAPI {

    let guid: AnyPublisher<String?, Never>

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

        guid = nativeWalletEnabled()
            .flatMap { isEnabled -> AnyPublisher<String?, Never> in
                guard isEnabled else {
                    return walletRepository.guid
                }
                return walletRepo.map(\.credentials.guid)
                    .map { key in key.isEmpty ? nil : key }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func set(guid: String) -> AnyPublisher<Void, Never> {
        nativeWalletEnabled()
            .flatMap { [walletRepo, walletRepository] isEnabled -> AnyPublisher<Void, Never> in
                guard isEnabled else {
                    return walletRepository.set(guid: guid)
                }
                return walletRepo.set(keyPath: \.credentials.guid, value: guid)
                    .mapToVoid()
            }
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
