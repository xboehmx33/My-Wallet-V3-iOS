// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinChainKit
import BitcoinKit
import DIKit
import FeatureTransactionDomain
import JavaScriptCore
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

final class BitcoinWallet: NSObject {

    // MARK: - Types

    fileprivate struct TransactionAmounts {
        let finalFee: MoneyValue
        let sweepAmount: MoneyValue
        let sweepFee: MoneyValue
    }

    enum BitcoinWalletError: Error {
        case v3PayloadDecodingFailed
        case v4PayloadDecodingFailed
    }

    typealias Dispatcher = BitcoinJSInteropDispatcherAPI & BitcoinJSInteropDelegateAPI
    typealias WalletAPI = LegacyBitcoinWalletProtocol & LegacyWalletAPI & MnemonicAccessAPI

    @objc var delegate: BitcoinJSInteropDelegateAPI {
        dispatcher
    }

    var interopDispatcher: BitcoinJSInteropDispatcherAPI {
        dispatcher
    }

    weak var reactiveWallet: ReactiveWalletAPI!

    @LazyInject private var secondPasswordPrompter: SecondPasswordPromptable
    private lazy var credentialsProvider: WalletCredentialsProviding = WalletManager.shared.legacyRepository
    private weak var wallet: WalletAPI?
    private let dispatcher: Dispatcher

    @objc convenience init(legacyWallet: Wallet) {
        self.init(wallet: legacyWallet)
    }

    init(
        wallet: WalletAPI,
        dispatcher: Dispatcher = BitcoinJSInteropDispatcher.shared
    ) {
        self.wallet = wallet
        self.dispatcher = dispatcher
    }

    @objc func setup(with context: JSContext) {

        context.setJsFunction(named: "objc_on_didGetDefaultBitcoinWalletIndexAsync" as NSString) { [weak self] defaultWalletIndex in
            self?.delegate.didGetDefaultWalletIndex(defaultWalletIndex)
        }
        context.setJsFunction(named: "objc_on_error_gettingDefaultBitcoinWalletIndexAsync" as NSString) { [weak self] errorMessage in
            self?.delegate.didFailToGetDefaultWalletIndex(errorMessage: errorMessage)
        }

        context.setJsFunction(named: "objc_on_didGetBitcoinWalletIndexAsync" as NSString) { [weak self] defaultWalletIndex in
            self?.delegate.didGetWalletIndex(defaultWalletIndex)
        }
        context.setJsFunction(named: "objc_on_error_gettingBitcoinWalletIndexAsync" as NSString) { [weak self] errorMessage in
            self?.delegate.didFailToGetDefaultWalletIndex(errorMessage: errorMessage)
        }

        context.setJsFunction(named: "objc_on_btc_tx_signed" as NSString) { [weak self] signedPayment in
            self?.delegate.didGetSignedPayment(signedPayment)
        }

        context.setJsFunction(named: "objc_on_btc_tx_signed_error" as NSString) { [weak self] errorMessage in
            self?.delegate.didFailToSignPayment(errorMessage: errorMessage)
        }

        context.setJsFunction(named: "objc_on_didGetBitcoinWalletsAsync" as NSString) { [weak self] accounts in
            self?.delegate.didGetAccounts(accounts)
        }
        context.setJsFunction(named: "objc_on_error_gettingBitcoinWalletsAsync" as NSString) { [weak self] errorMessage in
            self?.delegate.didFailToGetAccounts(errorMessage: errorMessage)
        }

        context.setJsFunction(named: "objc_on_didGetHDWalletAsync" as NSString) { [weak self] wallet in
            self?.delegate.didGetHDWallet(wallet)
        }
        context.setJsFunction(named: "objc_on_error_gettingHDWalletAsync" as NSString) { [weak self] errorMessage in
            self?.delegate.didFailToGetHDWallet(errorMessage: errorMessage)
        }
    }
}

extension BitcoinWallet: BitcoinChainSendBridgeAPI {

    func sign(with secondPassword: String?) -> Single<EngineTransaction> {
        Single.create(weak: self) { (self, observer) -> Disposable in
            self.wallet?.getSignedBitcoinPayment(
                with: secondPassword,
                success: { transactionHex, weight in
                    observer(.success(BitPayEngineTransaction(msgSize: weight, txHash: transactionHex)))
                },
                error: { json in
                    Logger.shared.error("BTC payment signing failure: \(json)")
                    observer(.error(PlatformKitError.default))
                }
            )
            return Disposables.create()
        }
    }

    func buildProposal<Token>(
        with destination: BitcoinChainReceiveAddress<Token>,
        amount: MoneyValue,
        fees: MoneyValue,
        source: CryptoAccount
    ) -> Single<BitcoinChainTransactionProposal<Token>> where Token: BitcoinChainToken {
        source
            .receiveAddress
            .map { $0 as! BitcoinChainReceiveAddress<Token> }
            .map(\.index)
            .map { index -> BitcoinChainTransactionProposal<Token> in
                .init(
                    destination: destination,
                    amount: amount,
                    fees: fees,
                    walletIndex: index,
                    source: source
                )
            }
    }

    func buildCandidate<Token>(
        with proposal: BitcoinChainTransactionProposal<Token>
    ) -> Single<BitcoinChainTransactionCandidate<Token>> {
        func buildCandidate(
            with legacyOrderCandidate: OrderTransactionLegacy
        ) -> Single<BitcoinChainTransactionCandidate<Token>> {
            Single.create(weak: self) { (self, observer) -> Disposable in
                self.wallet?.createOrderPayment(
                    orderTransaction: legacyOrderCandidate,
                    completion: { result in
                        switch result {
                        case .success(let json):
                            let amounts = Self.extractAmounts(
                                from: json,
                                cryptoCurrency: Token.coin.cryptoCurrency
                            )
                            let candidate = BitcoinChainTransactionCandidate<Token>(
                                proposal: proposal,
                                fees: amounts.finalFee,
                                sweepAmount: amounts.sweepAmount,
                                sweepFee: amounts.sweepFee
                            )
                            observer(.success(candidate))
                        case .failure(let error):
                            switch error {
                            case .createOrderFailed(let json):
                                Logger.shared.error("BTC Candidate build failure: \(json)")
                                /// NOTE: This error is mapped from the value that is returned from JS.
                                /// It's possible this error is not important and we always want to return
                                /// `.insufficientFunds`. However, we may want a different
                                ///  `TransactionValidationFailure.State` in the event that the user has the funds
                                /// but cannot cover fees.
                                let amounts = Self.extractAmounts(
                                    from: json,
                                    cryptoCurrency: Token.coin.cryptoCurrency
                                )
                                let errorMessage = json["error"] as? String ?? ""
                                let transactionError = BitcoinChainTransactionError(
                                    stringValue: errorMessage,
                                    finalFee: amounts.finalFee,
                                    sweepAmount: amounts.sweepAmount,
                                    sweepFee: amounts.sweepFee
                                )
                                observer(.error(transactionError))
                            }
                        }
                    }
                )
                return Disposables.create()
            }
        }
        let legacyOrderCandidate = OrderTransactionLegacy(
            legacyAssetType: Token.coin.cryptoCurrency.legacy,
            from: proposal.walletIndex,
            to: proposal.destination.address,
            amount: proposal.amount.toDisplayString(includeSymbol: false),
            fees: proposal.fees.toDisplayString(includeSymbol: false)
        )
        return Single.just(())
            .observeOn(MainScheduler.asyncInstance)
            .flatMap { _ -> Single<BitcoinChainTransactionCandidate<Token>> in
                buildCandidate(with: legacyOrderCandidate)
            }
    }

    private static func extractAmounts(
        from json: [AnyHashable: Any],
        cryptoCurrency: CryptoCurrency
    ) -> TransactionAmounts {
        let paymentJSON: [AnyHashable: Any] = json["payment"] as? [AnyHashable: Any] ?? [:]

        let finalFeeAny: Any = paymentJSON["finalFee"] ?? ""
        guard let finalFee = CryptoValue.create(minor: "\(finalFeeAny)", currency: cryptoCurrency) else {
            fatalError("We should always have a finalFee")
        }

        let sweepAmountAny: Any = paymentJSON["sweepAmount"] ?? ""
        let sweepAmount = CryptoValue.create(
            minor: "\(sweepAmountAny)",
            currency: cryptoCurrency
        ) ?? .zero(currency: cryptoCurrency)

        let sweepFeeAny: Any = paymentJSON["sweepFee"] ?? ""
        let sweepFee = CryptoValue.create(
            minor: "\(sweepFeeAny)",
            currency: cryptoCurrency
        ) ?? .zero(currency: cryptoCurrency)

        return TransactionAmounts(
            finalFee: finalFee.moneyValue,
            sweepAmount: sweepAmount.moneyValue,
            sweepFee: sweepFee.moneyValue
        )
    }

    func send(coin: BitcoinChainCoin, with secondPassword: String?) -> Single<String> {
        Single.create(weak: self) { (self, observer) -> Disposable in
            self.wallet?.sendOrderTransaction(
                coin.cryptoCurrency.legacy,
                secondPassword: secondPassword,
                completion: { result in
                    switch result {
                    case .success(let transactionHash):
                        observer(.success(transactionHash))
                    case .failure(let error):
                        switch error {
                        case .cancelled:
                            observer(.error(PlatformKitError.default))
                        case .sendOrderFailed(let message):
                            observer(.error(PlatformKitError.illegalStateException(message: message)))
                        }
                    }
                }
            )
            return Disposables.create()
        }
    }
}

extension BitcoinWallet: BitcoinWalletBridgeAPI {

    func update(accountIndex: Int, label: String) -> Completable {
        Completable.deferred { [weak self] () -> Completable in
            guard let wallet = self?.wallet else {
                return .error(WalletError.notInitialized)
            }
            return wallet.updateAccountLabel(.bitcoin, index: accountIndex, label: label)
        }
    }

    func walletIndex(for receiveAddress: String) -> Single<Int32> {
        Single<Int32>.create(weak: self) { (self, observer) -> Disposable in
            guard let wallet = self.wallet else {
                observer(.error(WalletError.notInitialized))
                return Disposables.create()
            }

            wallet.bitcoinWalletIndex(
                receiveAddress: receiveAddress,
                success: { walletIndex in
                    observer(.success(walletIndex))
                },
                error: { _ in
                    observer(.error(WalletError.unknown))
                }
            )
            return Disposables.create()
        }
    }

    func receiveAddress(forXPub xpub: String) -> Single<String> {
        reactiveWallet
            .waitUntilInitializedSingle
            .map(weak: self) { (self, _) -> String in
                guard let wallet = self.wallet else {
                    fatalError("Wallet was nil")
                }
                let result = wallet.getBitcoinReceiveAddress(forXPub: xpub, derivation: .default)
                switch result {
                case .success(let address):
                    return address
                case .failure(let error):
                    fatalError(String(describing: error))
                }
            }
    }

    func note(for transactionHash: String) -> Single<String?> {
        let note: Single<String?> = Single
            .create(weak: self) { (self, observer) -> Disposable in
                guard let wallet = self.wallet else {
                    return Disposables.create()
                }
                wallet.getBitcoinNote(
                    for: transactionHash,
                    success: { note in
                        observer(.success(note))
                    },
                    error: { _ in
                        observer(.error(WalletError.unknown))
                    }
                )
                return Disposables.create()
            }

        return reactiveWallet
            .waitUntilInitializedSingle
            .flatMap { note }
    }

    func updateNote(for transactionHash: String, note: String?) -> Completable {
        let setNote = Completable.create { completable in
            self.wallet?.setBitcoinNote(for: transactionHash, note: note)
            completable(.completed)
            return Disposables.create()
        }
        return reactiveWallet
            .waitUntilInitialized
            .flatMap { setNote.asObservable() }
            .asCompletable()
    }

    var defaultWallet: Single<BitcoinWalletAccount> {
        reactiveWallet
            .waitUntilInitializedSingle
            .flatMap(weak: self) { (self, _) -> Single<String?> in
                self.secondPasswordPrompter.secondPasswordIfNeeded(type: .actionRequiresPassword)
                    .asSingle()
            }
            .flatMap(weak: self) { (self, secondPassword) -> Single<BitcoinWalletAccount> in
                self.defaultWallet(secondPassword: secondPassword)
            }
    }

    private func defaultWallet(secondPassword: String?) -> Single<BitcoinWalletAccount> {
        bitcoinWallets(secondPassword: secondPassword)
            .flatMap { wallets -> Single<BitcoinWalletAccount> in
                self.defaultWalletIndex(secondPassword: secondPassword)
                    .map { index -> BitcoinWalletAccount in
                        guard let defaultWallet = wallets[safe: index] else {
                            throw WalletError.unknown
                        }
                        return defaultWallet
                    }
            }
    }

    var wallets: Single<[BitcoinWalletAccount]> {
        secondPasswordPrompter.secondPasswordIfNeeded(type: .actionRequiresPassword)
            .asSingle()
            .flatMap(weak: self) { (self, secondPassword) -> Single<[BitcoinWalletAccount]> in
                self.bitcoinWallets(secondPassword: secondPassword)
            }
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    }

    private func bitcoinWallets(secondPassword: String?) -> Single<[BitcoinWalletAccount]> {
        metadataWallets(secondPassword: secondPassword)
            .flatMap(weak: self) { (self, legacyWallets) -> Single<[BitcoinWalletAccount]> in
                guard let data = legacyWallets.data(using: .utf8) else {
                    throw WalletError.unknown
                }
                return self.decodeV3Wallets(from: data)
                    .flatMapError { _ -> Result<[BitcoinWalletAccount], BitcoinWalletError> in
                        self.decodeV4Wallets(from: data)
                    }
                    .single
            }
    }

    private func decodeV3Wallets(from data: Data) -> Result<[BitcoinWalletAccount], BitcoinWalletError> {
        Result { try JSONDecoder().decode([PayloadBitcoinWalletAccountV3].self, from: data) }
            .replaceError(with: BitcoinWalletError.v3PayloadDecodingFailed)
            .map { payload -> [BitcoinWalletAccount] in
                payload.enumerated()
                    .map { index, account -> BitcoinWalletAccount in
                        BitcoinWalletAccount(index: index, account: account)
                    }
            }
    }

    private func decodeV4Wallets(from data: Data) -> Result<[BitcoinWalletAccount], BitcoinWalletError> {
        Result { try JSONDecoder().decode([PayloadBitcoinWalletAccountV4].self, from: data) }
            .replaceError(with: BitcoinWalletError.v4PayloadDecodingFailed)
            .map { payload -> [BitcoinWalletAccount] in
                payload.enumerated()
                    .map { index, account -> BitcoinWalletAccount in
                        BitcoinWalletAccount(index: index, account: account)
                    }
            }
    }

    private func metadataWallets(secondPassword: String?) -> Single<String> {
        Single<String>.create(weak: self) { (self, observer) -> Disposable in
            guard let wallet = self.wallet else {
                observer(.error(WalletError.notInitialized))
                return Disposables.create()
            }
            wallet.bitcoinWallets(
                with: secondPassword,
                success: { accounts in observer(.success(accounts)) },
                error: { _ in observer(.error(WalletError.unknown)) }
            )
            return Disposables.create()
        }
    }

    private func defaultWalletIndex(secondPassword: String?) -> Single<Int> {
        Single<Int>.create(weak: self) { (self, observer) -> Disposable in
            guard let wallet = self.wallet else {
                observer(.error(WalletError.notInitialized))
                return Disposables.create()
            }
            wallet.bitcoinDefaultWalletIndex(
                with: secondPassword,
                success: { defaultWalletIndex in
                    observer(.success(defaultWalletIndex))
                },
                error: { _ in
                    observer(.error(WalletError.unknown))
                }
            )
            return Disposables.create()
        }
    }
}

extension BitcoinWallet: MnemonicAccessAPI {
    var mnemonic: Maybe<Mnemonic> {
        guard let wallet = wallet else {
            return Maybe.empty()
        }
        return wallet.mnemonic
    }

    var mnemonicPromptingIfNeeded: Maybe<Mnemonic> {
        guard let wallet = wallet else {
            return Maybe.empty()
        }
        return wallet.mnemonicPromptingIfNeeded
    }

    func mnemonic(with secondPassword: String?) -> Single<Mnemonic> {
        guard let wallet = wallet else {
            return .error(PlatformKitError.default)
        }
        return wallet.mnemonic(with: secondPassword)
    }
}
