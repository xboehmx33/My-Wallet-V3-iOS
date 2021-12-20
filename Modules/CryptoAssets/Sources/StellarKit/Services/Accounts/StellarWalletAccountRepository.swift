// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxSwift

public protocol StellarWalletAccountRepositoryAPI {
    var defaultAccount: StellarWalletAccount? { get }

    func initializeMetadataMaybe() -> Maybe<StellarWalletAccount>
    func loadKeyPair() -> Maybe<StellarKeyPair>
    func loadKeyPair(with secondPassword: String?) -> Single<StellarKeyPair>
}

class StellarWalletAccountRepository: StellarWalletAccountRepositoryAPI, WalletAccountInitializer {
    typealias WalletAccount = StellarWalletAccount

    private let bridge: StellarWalletBridgeAPI
    private let mnemonicAccessAPI: MnemonicAccessAPI
    private let deriver = StellarKeyPairDeriver()

    init(
        bridge: StellarWalletBridgeAPI = resolve(),
        mnemonicAccessAPI: MnemonicAccessAPI = resolve()
    ) {
        self.bridge = bridge
        self.mnemonicAccessAPI = mnemonicAccessAPI
    }

    func initializeMetadataMaybe() -> Maybe<WalletAccount> {
        loadDefaultAccount().ifEmpty(
            switchTo: createAndSaveStellarAccount()
        )
    }

    /// The default `StellarWallet`, will be nil if it has not yet been initialized
    var defaultAccount: StellarWalletAccount? {
        accounts().first
    }

    func accounts() -> [WalletAccount] {
        bridge.stellarWallets()
    }

    func loadKeyPair(with secondPassword: String?) -> Single<StellarKeyPair> {
        mnemonicAccessAPI
            .mnemonic(with: secondPassword)
            .map { mnemonic in
                StellarKeyDerivationInput(mnemonic: mnemonic)
            }
            .flatMap(weak: self) { (self, input) -> Single<StellarKeyPair> in
                self.derive(input: input)
            }
    }

    func loadKeyPair() -> Maybe<StellarKeyPair> {
        mnemonicAccessAPI
            .mnemonicPromptingIfNeeded
            .map { mnemonic in
                StellarKeyDerivationInput(mnemonic: mnemonic)
            }
            .flatMap(weak: self) { (self, input) -> Maybe<StellarKeyPair> in
                self.derive(input: input).asMaybe()
            }
    }

    // MARK: Private

    private func derive(input: StellarKeyDerivationInput) -> Single<StellarKeyPair> {
        Single
            .create(weak: self) { (self, observer) -> Disposable in
                switch self.deriver.derive(input: input) {
                case .success(let success):
                    observer(.success(success))
                case .failure(let error):
                    observer(.error(error))
                }
                return Disposables.create()
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }

    private func loadDefaultAccount() -> Maybe<WalletAccount> {
        guard let defaultAccount = defaultAccount else {
            return Maybe.empty()
        }
        return Maybe.just(defaultAccount)
    }

    private func createAndSaveStellarAccount() -> Maybe<WalletAccount> {
        loadKeyPair()
            .flatMap(weak: self) { (self, keyPair) -> Maybe<StellarKeyPair> in
                self.save(keyPair: keyPair)
                    .andThen(Maybe.just(keyPair))
            }
            .map { keyPair -> Account in
                Account(
                    index: 0,
                    publicKey: keyPair.accountID,
                    label: CryptoCurrency.coin(.stellar).defaultWalletName,
                    archived: false
                )
            }
    }

    private func save(keyPair: StellarKeyPair) -> Completable {
        Completable.create(weak: self) { (self, observer) -> Disposable in
            self.bridge.save(
                keyPair: keyPair,
                label: CryptoCurrency.coin(.stellar).defaultWalletName,
                completion: { result in
                    switch result {
                    case .success:
                        observer(.completed)
                    case .failure:
                        observer(.error(StellarAccountError.unableToSaveNewAccount))
                    }
                }
            )
            return Disposables.create()
        }
        .subscribeOn(MainScheduler.asyncInstance)
    }
}
