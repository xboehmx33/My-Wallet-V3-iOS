// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import EthereumKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift
import RxToolKit
import ToolKit

final class ERC20OnChainTransactionEngine: OnChainTransactionEngine {

    // MARK: - OnChainTransactionEngine

    let currencyConversionService: CurrencyConversionServiceAPI
    let walletCurrencyService: FiatCurrencyServiceAPI

    var askForRefreshConfirmation: AskForRefreshConfirmation!

    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        sourceExchangeRatePair
            .map { pair -> TransactionMoneyValuePairs in
                TransactionMoneyValuePairs(
                    source: pair,
                    destination: pair
                )
            }
            .asObservable()
    }

    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!

    let requireSecondPassword: Bool

    // MARK: - Private Properties

    private let erc20Token: AssetModel
    private let feeCache: CachedValue<EthereumTransactionFee>
    private let feeService: EthereumKit.EthereumFeeServiceAPI
    private let ethereumAccountDetails: EthereumAccountDetailsServiceAPI
    private let transactionBuildingService: EthereumTransactionBuildingServiceAPI
    private let ethereumTransactionDispatcher: EthereumTransactionDispatcherAPI
    private let transactionsService: EthereumHistoricalTransactionServiceAPI
    private var target: ERC20ReceiveAddress {
        transactionTarget as! ERC20ReceiveAddress
    }

    // MARK: - Init

    init(
        erc20Token: AssetModel,
        requireSecondPassword: Bool,
        ethereumAccountDetails: EthereumAccountDetailsServiceAPI = resolve(),
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        feeService: EthereumKit.EthereumFeeServiceAPI = resolve(),
        transactionsService: EthereumHistoricalTransactionServiceAPI = resolve(),
        transactionBuildingService: EthereumTransactionBuildingServiceAPI = resolve(),
        ethereumTransactionDispatcher: EthereumTransactionDispatcherAPI = resolve()
    ) {
        self.erc20Token = erc20Token
        self.ethereumAccountDetails = ethereumAccountDetails
        self.walletCurrencyService = walletCurrencyService
        self.currencyConversionService = currencyConversionService
        self.feeService = feeService
        self.requireSecondPassword = requireSecondPassword
        self.transactionsService = transactionsService
        self.transactionBuildingService = transactionBuildingService
        self.ethereumTransactionDispatcher = ethereumTransactionDispatcher

        feeCache = CachedValue(
            configuration: .onSubscription(
                schedulerIdentifier: "ERC20OnChainTransactionEngine"
            )
        )
        feeCache.setFetch(weak: self) { (self) -> Single<EthereumTransactionFee> in
            self.feeService.fees(cryptoCurrency: self.sourceCryptoCurrency)
        }
    }

    // MARK: - OnChainTransactionEngine

    func assertInputsValid() {
        defaultAssertInputsValid()
        precondition(sourceCryptoCurrency.isERC20)
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        Single.zip(
            walletCurrencyService
                .displayCurrency
                .asSingle(),
            availableBalance
        )

        .map { [erc20Token] fiatCurrency, availableBalance -> PendingTransaction in
            .init(
                amount: .zero(currency: .erc20(erc20Token)),
                available: availableBalance,
                feeAmount: .zero(currency: .coin(.ethereum)),
                feeForFullAvailable: .zero(currency: .coin(.ethereum)),
                feeSelection: .init(
                    selectedLevel: .regular,
                    availableLevels: [.regular, .priority],
                    asset: .crypto(.coin(.ethereum))
                ),
                selectedFiatCurrency: fiatCurrency
            )
        }
    }

    func start(
        sourceAccount: CryptoAccount,
        transactionTarget: TransactionTarget,
        askForRefreshConfirmation: @escaping AskForRefreshConfirmation
    ) {
        self.sourceAccount = sourceAccount
        self.transactionTarget = transactionTarget
        self.askForRefreshConfirmation = askForRefreshConfirmation
    }

    func restart(
        transactionTarget: TransactionTarget,
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        defaultRestart(
            transactionTarget: transactionTarget,
            pendingTransaction: pendingTransaction
        )
    }

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        Single
            .zip(
                fiatAmountAndFees(from: pendingTransaction),
                makeFeeSelectionOption(pendingTransaction: pendingTransaction)
            )
            .map { fiatAmountAndFees, feeSelectionOption ->
                (
                    amountInFiat: MoneyValue,
                    feesInFiat: MoneyValue,
                    feeSelectionOption: TransactionConfirmation.Model.FeeSelection
                ) in
                let (amountInFiat, feesInFiat) = fiatAmountAndFees
                return (amountInFiat.moneyValue, feesInFiat.moneyValue, feeSelectionOption)
            }
            .map(weak: self) { (self, payload) -> [TransactionConfirmation] in
                [
                    .sendDestinationValue(.init(value: pendingTransaction.amount)),
                    .source(.init(value: self.sourceAccount.label)),
                    .destination(.init(value: self.target.label)),
                    .feeSelection(payload.feeSelectionOption),
                    .feedTotal(
                        .init(
                            amount: pendingTransaction.amount,
                            amountInFiat: payload.amountInFiat,
                            fee: pendingTransaction.feeAmount,
                            feeInFiat: payload.feesInFiat
                        )
                    )
                ]
            }
            .map { pendingTransaction.update(confirmations: $0) }
    }

    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        guard sourceAccount != nil else {
            return .just(pendingTransaction)
        }
        guard let crypto = amount.cryptoValue else {
            return .error(TransactionValidationFailure(state: .unknownError))
        }
        guard crypto.currencyType == .erc20(erc20Token) else {
            return .error(TransactionValidationFailure(state: .unknownError))
        }
        return Single.zip(
            sourceAccount.actionableBalance,
            absoluteFee(with: pendingTransaction.feeLevel, fetch: true)
        )
        .map { values -> PendingTransaction in
            let (actionableBalance, fee) = values
            return pendingTransaction.update(
                amount: amount,
                available: actionableBalance,
                fee: fee.moneyValue,
                feeForFullAvailable: fee.moneyValue
            )
        }
    }

    func doOptionUpdateRequest(
        pendingTransaction: PendingTransaction,
        newConfirmation: TransactionConfirmation
    ) -> Single<PendingTransaction> {
        switch newConfirmation {
        case .feeSelection(let value) where value.selectedLevel != pendingTransaction.feeLevel:
            return updateFeeSelection(
                pendingTransaction: pendingTransaction,
                newFeeLevel: value.selectedLevel,
                customFeeAmount: nil
            )
        default:
            return defaultDoOptionUpdateRequest(
                pendingTransaction: pendingTransaction,
                newConfirmation: newConfirmation
            )
        }
    }

    func validateAmount(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmounts(pendingTransaction: pendingTransaction)
            .andThen(validateSufficientFunds(pendingTransaction: pendingTransaction))
            .andThen(validateSufficientGas(pendingTransaction: pendingTransaction))
            .updateTxValidityCompletable(pendingTransaction: pendingTransaction)
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmounts(pendingTransaction: pendingTransaction)
            .andThen(validateSufficientFunds(pendingTransaction: pendingTransaction))
            .andThen(validateSufficientGas(pendingTransaction: pendingTransaction))
            .andThen(validateNoPendingTransaction())
            .updateTxValidityCompletable(pendingTransaction: pendingTransaction)
    }

    func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult> {
        Single.zip(feeCache.valueSingle, .just(target.address))
            .flatMap { [erc20Token, transactionBuildingService] fee, address -> Single<EthereumTransactionCandidate> in
                transactionBuildingService.buildTransaction(
                    amount: pendingTransaction.amount,
                    to: EthereumAddress(address: address)!,
                    feeLevel: pendingTransaction.feeLevel,
                    fee: fee,
                    contractAddress: erc20Token.contractAddress
                )
                .single
            }
            .flatMap(weak: self) { (self, candidate) -> Single<EthereumTransactionPublished> in
                self.ethereumTransactionDispatcher.send(
                    transaction: candidate,
                    secondPassword: secondPassword
                )
            }
            .map(\.transactionHash)
            .map { transactionHash -> TransactionResult in
                .hashed(txHash: transactionHash, amount: pendingTransaction.amount)
            }
    }
}

extension ERC20OnChainTransactionEngine {

    private func validateNoPendingTransaction() -> Completable {
        transactionsService
            .isWaitingOnTransaction
            .map { isWaitingOnTransaction -> Void in
                guard isWaitingOnTransaction == false else {
                    throw TransactionValidationFailure(state: .transactionInFlight)
                }
            }
            .asCompletable()
    }

    private func validateAmounts(pendingTransaction: PendingTransaction) -> Completable {
        Completable.fromCallable { [erc20Token] in
            guard try pendingTransaction.amount > .zero(currency: .erc20(erc20Token)) else {
                throw TransactionValidationFailure(state: .belowMinimumLimit(pendingTransaction.minSpendable))
            }
        }
    }

    private func validateSufficientFunds(pendingTransaction: PendingTransaction) -> Completable {
        guard sourceAccount != nil else {
            fatalError("sourceAccount should never be nil when this is called")
        }
        return sourceAccount
            .actionableBalance
            .map { [sourceAccount, transactionTarget] actionableBalance -> Void in
                guard try pendingTransaction.amount <= actionableBalance else {
                    throw TransactionValidationFailure(
                        state: .insufficientFunds(
                            actionableBalance,
                            pendingTransaction.amount,
                            sourceAccount!.currencyType,
                            transactionTarget!.currencyType
                        )
                    )
                }
            }
            .asCompletable()
    }

    private func validateSufficientGas(pendingTransaction: PendingTransaction) -> Completable {
        Single
            .zip(
                ethereumAccountBalance,
                absoluteFee(with: pendingTransaction.feeLevel)
            )
            .map { balance, absoluteFee -> Void in
                guard try absoluteFee <= balance else {
                    throw TransactionValidationFailure(
                        state: .belowFees(absoluteFee.moneyValue, balance.moneyValue)
                    )
                }
            }
            .asCompletable()
    }

    private func makeFeeSelectionOption(
        pendingTransaction: PendingTransaction
    ) -> Single<TransactionConfirmation.Model.FeeSelection> {
        getFeeState(pendingTransaction: pendingTransaction)
            .map { feeState -> TransactionConfirmation.Model.FeeSelection in
                TransactionConfirmation.Model.FeeSelection(
                    feeState: feeState,
                    selectedLevel: pendingTransaction.feeLevel,
                    fee: pendingTransaction.feeAmount
                )
            }
    }

    private func fiatAmountAndFees(
        from pendingTransaction: PendingTransaction
    ) -> Single<(amount: FiatValue, fees: FiatValue)> {
        Single.zip(
            sourceExchangeRatePair,
            ethereumExchangeRatePair,
            .just(pendingTransaction.amount.cryptoValue ?? .zero(currency: .erc20(erc20Token))),
            .just(pendingTransaction.feeAmount.cryptoValue ?? .zero(currency: .erc20(erc20Token)))
        )
        .map { sourceExchange, ethereumExchange, amount, feeAmount -> (FiatValue, FiatValue) in
            let erc20Quote = sourceExchange.quote.fiatValue!
            let ethereumQuote = ethereumExchange.quote.fiatValue!
            let fiatAmount = amount.convertToFiatValue(exchangeRate: erc20Quote)
            let fiatFees = feeAmount.convertToFiatValue(exchangeRate: ethereumQuote)
            return (fiatAmount, fiatFees)
        }
    }

    private func absoluteFee(with feeLevel: FeeLevel, fetch: Bool = false) -> Single<CryptoValue> {
        feeCache.valueSingle
            .map { fees -> CryptoValue in
                fees.absoluteFee(with: feeLevel.ethereumFeeLevel, isContract: true)
            }
    }

    private var ethereumAccountBalance: Single<CryptoValue> {
        ethereumAccountDetails.accountDetails().map(\.balance)
    }

    /// Streams `MoneyValuePair` for the exchange rate of the source ERC20 Asset in the current fiat currency.
    private var sourceExchangeRatePair: Single<MoneyValuePair> {
        walletCurrencyService
            .displayCurrency
            .flatMap { [currencyConversionService, sourceAsset] fiatCurrency in
                currencyConversionService
                    .conversionRate(from: sourceAsset, to: fiatCurrency.currencyType)
                    .map { MoneyValuePair(base: .one(currency: sourceAsset), quote: $0) }
            }
            .asSingle()
    }

    /// Streams `MoneyValuePair` for the exchange rate of Ethereum in the current fiat currency.
    private var ethereumExchangeRatePair: Single<MoneyValuePair> {
        walletCurrencyService
            .displayCurrency
            .flatMap { [currencyConversionService] fiatCurrency in
                currencyConversionService
                    .conversionRate(from: .crypto(.coin(.ethereum)), to: fiatCurrency.currencyType)
                    .map { MoneyValuePair(base: .one(currency: .crypto(.coin(.ethereum))), quote: $0) }
            }
            .asSingle()
    }
}
