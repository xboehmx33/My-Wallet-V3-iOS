// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import WalletPayloadKit

final class CredentialsRepository: CredentialsRepositoryAPI {

    let guid: AnyPublisher<String?, Never>
    let sharedKey: AnyPublisher<String?, Never>

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

        sharedKey = nativeWalletEnabled()
            .flatMap { isEnabled -> AnyPublisher<String?, Never> in
                guard isEnabled else {
                    return walletRepository.sharedKey
                }
                return walletRepo.map(\.credentials.sharedKey)
                    .map { key in key.isEmpty ? nil : key }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - GuidRepositoryAPI

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

    // MARK: - SharedKeyRepositoryAPI

    func set(sharedKey: String) -> AnyPublisher<Void, Never> {
        nativeWalletEnabled()
            .flatMap { [walletRepo, walletRepository] isEnabled -> AnyPublisher<Void, Never> in
                guard isEnabled else {
                    return walletRepository.set(sharedKey: sharedKey)
                }
                return walletRepo.set(keyPath: \.credentials.sharedKey, value: sharedKey)
                    .mapToVoid()
            }
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
