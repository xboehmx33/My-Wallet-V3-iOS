// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Foundation
import KeychainKit

struct WalletRepoKeychain {
    static let repoTag: String = "repo.tag"
}

extension DependencyContainer {

    // MARK: - WalletPayloadKit Module

    public static var walletPayloadKit = module {

        single { () -> WalletRepo in
            let keychainAccess: KeychainAccessAPI = DIKit.resolve(tag: WalletRepoKeychain.repoTag)
            let initialStateOrEmpty = retrieveWalletRepoState(keychainAccess: keychainAccess) ?? .empty
            return WalletRepo(initialState: initialStateOrEmpty)
        }

        single { () -> WalletRepoPersistenceAPI in
            let repo: WalletRepo = DIKit.resolve()
            let queue = DispatchQueue(label: "wallet.persistence.queue", qos: .default)
            let keychainAccess: KeychainAccessAPI = DIKit.resolve(tag: WalletRepoKeychain.repoTag)
            return WalletRepoPersistence(
                repo: repo,
                keychainAccess: keychainAccess,
                queue: queue
            )
        }

        factory { () -> WalletFetcherAPI in
            let queue = DispatchQueue(label: "wallet.fetching.op.queue", qos: .userInitiated)
            return WalletFetcher(
                walletRepo: DIKit.resolve(),
                payloadCrypto: DIKit.resolve(),
                walletLogic: DIKit.resolve(),
                operationsQueue: queue
            )
        }

        factory {
            WalletLogic(
                holder: DIKit.resolve()
            )
        }

        factory { () -> ReleasableWalletAPI in
            let holder: WalletHolder = DIKit.resolve()
            return holder as ReleasableWalletAPI
        }

        factory { () -> InMemoryWalletProviderAPI in
            let holder: WalletHolder = DIKit.resolve()
            return holder as InMemoryWalletProviderAPI
        }

        factory { () -> WalletHolderAPI in
            let holder: WalletHolder = DIKit.resolve()
            return holder as WalletHolderAPI
        }

        single { WalletHolder() }

        single(tag: WalletRepoKeychain.repoTag) { () -> KeychainAccessAPI in
            KeychainAccess(service: "com.blockchain.wallet-repo")
        }

        factory { WalletCryptoService() as WalletCryptoServiceAPI }

        factory { WalletPayloadCryptor() as WalletPayloadCryptorAPI }

        factory { PayloadCrypto() as PayloadCryptoAPI }

        factory { AESCryptor() as AESCryptorAPI }

        // MARK: Wallet Upgrade

        factory { WalletUpgradeService() as WalletUpgradeServicing }

        factory { WalletUpgradeJSService() as WalletUpgradeJSServicing }
    }
}
