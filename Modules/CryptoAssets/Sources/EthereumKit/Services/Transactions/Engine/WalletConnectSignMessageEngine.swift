// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import FeatureTransactionDomain
import Localization
import MoneyKit
import PlatformKit
import RxSwift
import RxToolKit
import ToolKit

final class WalletConnectSignMessageEngine: TransactionEngine {

    let currencyConversionService: CurrencyConversionServiceAPI
    let walletCurrencyService: FiatCurrencyServiceAPI

    var askForRefreshConfirmation: AskForRefreshConfirmation!
    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!

    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        walletCurrencyService
            .fiatCurrencyPublisher
            .map { fiatCurrency -> MoneyValuePair in
                MoneyValuePair(
                    base: .one(currency: .crypto(.coin(.ethereum))),
                    quote: .one(currency: fiatCurrency)
                )
            }
            .map { pair -> TransactionMoneyValuePairs in
                TransactionMoneyValuePairs(
                    source: pair,
                    destination: pair
                )
            }
            .asObservable()
    }

    let requireSecondPassword: Bool = false

    private var ethereumSignTarget: EthereumSignMessageTarget {
        transactionTarget as! EthereumSignMessageTarget
    }

    private let keyPairProvider: AnyKeyPairProvider<EthereumKeyPair>
    private let ethereumSigner: EthereumSignerAPI
    private let feeService: EthereumFeeServiceAPI

    init(
        ethereumSigner: EthereumSignerAPI = resolve(),
        keyPairProvider: AnyKeyPairProvider<EthereumKeyPair> = resolve(),
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        feeService: EthereumFeeServiceAPI = resolve()
    ) {
        self.ethereumSigner = ethereumSigner
        self.feeService = feeService
        self.keyPairProvider = keyPairProvider
        self.walletCurrencyService = walletCurrencyService
        self.currencyConversionService = currencyConversionService
    }

    func assertInputsValid() {
        precondition(sourceAccount is CryptoNonCustodialAccount)
        precondition(sourceCryptoCurrency == .coin(.ethereum))
        precondition(transactionTarget is EthereumSignMessageTarget)
    }

    func start(
        sourceAccount: BlockchainAccount,
        transactionTarget: TransactionTarget,
        askForRefreshConfirmation: @escaping AskForRefreshConfirmation
    ) {
        self.sourceAccount = sourceAccount
        self.transactionTarget = transactionTarget
        self.askForRefreshConfirmation = askForRefreshConfirmation
    }

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        let notice = TransactionConfirmation.Model.Notice(
            value: LocalizationConstants.Transaction.Sign.dappRequestWarning
        )
        let app = TransactionConfirmation.Model.App(
            dAppAddress: ethereumSignTarget.dAppAddress,
            dAppName: ethereumSignTarget.dAppName
        )
        let network = TransactionConfirmation.Model.Network(
            network: AssetModel.ethereum.name
        )
        let message = TransactionConfirmation.Model.Message(
            dAppName: ethereumSignTarget.dAppName,
            message: ethereumSignTarget.readableMessage
        )
        return .just(
            pendingTransaction.update(
                confirmations: [
                    .notice(notice),
                    .app(app),
                    .network(network),
                    .message(message)
                ]
            )
        )
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        walletCurrencyService
            .fiatCurrency
            .map { fiatCurrency -> PendingTransaction in
                .init(
                    amount: .one(currency: .coin(.ethereum)),
                    available: .zero(currency: .coin(.ethereum)),
                    feeAmount: .zero(currency: .coin(.ethereum)),
                    feeForFullAvailable: .zero(currency: .coin(.ethereum)),
                    feeSelection: .init(
                        selectedLevel: .regular,
                        availableLevels: [.regular],
                        asset: .crypto(.coin(.ethereum))
                    ),
                    selectedFiatCurrency: fiatCurrency
                )
            }
    }

    func doRefreshConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        .just(pendingTransaction)
    }

    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        .just(pendingTransaction)
    }

    func validateAmount(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        Single
            .just(pendingTransaction.update(validationState: .canExecute))
            .updateTxValiditySingle(pendingTransaction: pendingTransaction)
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        sourceAccount.receiveAddress
            .map { [ethereumSignTarget] receiveAddress in
                guard receiveAddress.address.caseInsensitiveCompare(ethereumSignTarget.account) == .orderedSame else {
                    throw TransactionValidationFailure(state: .invalidAddress)
                }
                return pendingTransaction
            }
            .updateTxValiditySingle(pendingTransaction: pendingTransaction)
    }

    func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult> {
        keyPairProvider
            .keyPair(with: secondPassword)
            .flatMap { [ethereumSigner, ethereumSignTarget] ethereumKeyPair -> Single<Data> in
                switch ethereumSignTarget.message {
                case .data(let data):
                    return ethereumSigner
                        .sign(messageData: data, keyPair: ethereumKeyPair)
                        .single
                case .typedData(let typedData):
                    return ethereumSigner
                        .signTypedData(messageJson: typedData, keyPair: ethereumKeyPair)
                        .single
                }
            }
            .map { personalSigned -> TransactionResult in
                .signed(rawTx: personalSigned.hexString.withHex)
            }
    }

    func doPostExecute(transactionResult: TransactionResult) -> Completable {
        transactionTarget.onTxCompleted(transactionResult)
    }

    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction> {
        .just(pendingTransaction)
    }
}
