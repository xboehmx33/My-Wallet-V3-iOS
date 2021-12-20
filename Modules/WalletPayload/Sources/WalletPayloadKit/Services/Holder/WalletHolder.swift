// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import MetadataKit
import ToolKit
import WalletCore

enum WalletState {
    case partial(wallet: Wallet)
    case loaded(wallet: Wallet, metadata: MetadataState)

    var isInitialised: Bool {
        isMetadataInitialised
    }

    var wallet: Wallet {
        switch self {
        case .partial(wallet: let wallet):
            return wallet
        case .loaded(wallet: let wallet, _):
            return wallet
        }
    }

    var metadata: MetadataState? {
        switch self {
        case .partial:
            return nil
        case .loaded(_, metadata: let metadata):
            return metadata
        }
    }

    private var isMetadataInitialised: Bool {
        metadata != nil
    }
}

typealias WalletCreating = (BlockchainWallet) -> Wallet

/// Responsible for holding a decoded wallet in memory
final class WalletHolder: WalletHolderAPI, InMemoryWalletProviderAPI, ReleasableWalletAPI {

    var walletStatePublisher: AnyPublisher<WalletState?, Never> {
        walletState.publisher
    }

    private(set) var walletState = Atomic<WalletState?>(nil)

    func provideWallet() -> WalletState? {
        walletState.value
    }

    func hold(
        walletState: WalletState
    ) -> AnyPublisher<WalletState, Never> {
        Deferred { [weak self] in
            Future<WalletState, Never> { promise in
                self?.walletState.mutate { $0 = walletState }
                promise(
                    .success(walletState)
                )
            }
        }
        .setFailureType(to: Never.self)
        .eraseToAnyPublisher()
    }

    func release() {
        // TODO: It might be more than just this... revisit
        walletState.mutate { $0 = nil }
    }
}

/// Creates a new `Wallet` object
/// - Parameter blockchainWallet: A value of `BlockchainWallet`
/// - Returns: A function that provides a new `Wallet` object
func createWallet(
    from blockchainWallet: BlockchainWallet
) -> Wallet {
    Wallet(from: blockchainWallet)
}
