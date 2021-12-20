// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import MetadataKit
import ToolKit

final class WalletLogic {

    private let holder: WalletHolderAPI
    private let creator: WalletCreating
    private let metadata: MetadataServiceAPI

    init(
        holder: WalletHolderAPI,
        creator: @escaping WalletCreating = createWallet(from:),
        metadata: MetadataServiceAPI = resolve()
    ) {
        self.holder = holder
        self.creator = creator
        self.metadata = metadata
    }

    func initialize(
        with password: String,
        secondPassword: String
    ) -> AnyPublisher<WalletState, WalletError> {
        holder.walletStatePublisher
            .flatMap { walletState -> AnyPublisher<WalletState, WalletError> in
                guard let walletState = walletState else {
                    return .failure(.payloadNotFound) // TODO:
                }
                return .just(walletState)
            }
            .map(\.wallet)
            .flatMap { [initialiseMetadataWithSecondPassword] wallet
                -> AnyPublisher<WalletState, WalletError> in
                initialiseMetadataWithSecondPassword(wallet, password, secondPassword)
            }
            .eraseToAnyPublisher()
    }

    /// Initialises a `Wallet` using the given payload data
    /// - Parameter payload: A `Data` value representing a valid decrypted wallet payload
    /// - Returns: `AnyPublisher<EmptyValue, WalletError>`
    func initialize(
        with password: String,
        payload: Data
    ) -> AnyPublisher<WalletState, WalletError> {
        decode(data: payload)
            .map { [creator] (wallet: BlockchainWallet) -> Wallet in
                creator(wallet)
            }
            .flatMap { [holder] wallet -> AnyPublisher<Wallet, WalletError> in
                holder.hold(walletState: .partial(wallet: wallet))
                    .map(\.wallet)
                    .setFailureType(to: WalletError.self)
                    .eraseToAnyPublisher()
            }
            .flatMap { [initialiseMetadata] wallet -> AnyPublisher<WalletState, WalletError> in
                initialiseMetadata(wallet, password)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func initialiseMetadataWithSecondPassword(
        with wallet: Wallet,
        password: String,
        secondPassword: String
    ) -> AnyPublisher<WalletState, WalletError> {
        guard wallet.doubleEncrypted else {
            fatalError("This method should only be called if a secondPassword is needed")
        }
        return initialiseMetadata(with: wallet, password: password, secondPassword: nil)
    }

    private func initialiseMetadata(
        with wallet: Wallet,
        password: String
    ) -> AnyPublisher<WalletState, WalletError> {
        if wallet.doubleEncrypted {
            return .failure(.initialization(.needsSecondPassword))
        }
        return initialiseMetadata(with: wallet, password: password, secondPassword: nil)
    }

    private func initialiseMetadata(
        with wallet: Wallet,
        password: String,
        secondPassword: String?
    ) -> AnyPublisher<WalletState, WalletError> {
        provideMetadataInput(
            password: password,
            secondPassword: secondPassword,
            wallet: wallet
        )
        .map { input in
            (input, wallet)
        }
        .flatMap { [metadata] input, wallet -> AnyPublisher<WalletState, WalletError> in
            metadata.initialize(
                credentials: input.credentials,
                masterKey: input.masterKey,
                payloadIsDoubleEncrypted: input.payloadIsDoubleEncrypted
            )
            .map { metadataState -> WalletState in
                .loaded(wallet: wallet, metadata: metadataState)
            }
            .replaceError(with: .initialization(.metadataInitialization))
            .eraseToAnyPublisher()
        }
        .flatMap { [holder] walletState
            -> AnyPublisher<WalletState, WalletError> in
            holder.hold(walletState: walletState)
                .setFailureType(to: WalletError.self)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    private func decode(data: Data) -> AnyPublisher<BlockchainWallet, WalletError> {
        Result {
            try JSONDecoder().decode(BlockchainWallet.self, from: data)
        }
        .mapError { WalletError.decryption(.decodeError($0)) }
        .publisher
        .eraseToAnyPublisher()
    }
}

struct MetadataInput {
    let credentials: Credentials
    let masterKey: MasterKey
    let payloadIsDoubleEncrypted: Bool
}

func provideMetadataInput(
    password: String,
    secondPassword: String?,
    wallet: Wallet
) -> AnyPublisher<MetadataInput, WalletError> {
    getSeedHex(wallet: wallet, secondPassword: secondPassword)
        .flatMap(masterKeyFrom(seedHex:))
        .map { masterKey -> MetadataInput in
            let credentials = Credentials(
                guid: wallet.guid,
                sharedKey: wallet.sharedKey,
                password: password
            )
            return MetadataInput(
                credentials: credentials,
                masterKey: masterKey,
                payloadIsDoubleEncrypted: wallet.doubleEncrypted
            )
        }
        .publisher
        .eraseToAnyPublisher()
}

private func masterKeyFrom(seedHex: String) -> Result<MasterKey, WalletError> {
    MasterKey.from(seedHex: seedHex)
        .mapError { _ -> WalletError in
            .initialization(.metadataInitialization)
        }
}
