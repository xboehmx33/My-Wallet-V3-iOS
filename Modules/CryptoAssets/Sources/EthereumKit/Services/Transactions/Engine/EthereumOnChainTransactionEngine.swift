// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift
import RxToolKit
import ToolKit

final class EthereumOnChainTransactionEngine: OnChainTransactionEngine {

    // MARK: - OnChainTransactionEngine

    let currencyConversionService: CurrencyConversionServiceAPI
    let walletCurrencyService: FiatCurrencyServiceAPI

    var askForRefreshConfirmation: AskForRefreshConfirmation!

    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!
    let requireSecondPassword: Bool
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

    // MARK: - Private Properties

    private let feeCache: CachedValue<EthereumTransactionFee>
    private let feeService: EthereumFeeServiceAPI
    private let ethereumAccountService: EthereumAccountServiceAPI
    private let transactionBuildingService: EthereumTransactionBuildingServiceAPI
    private let transactionsService: EthereumHistoricalTransactionServiceAPI
    private let ethereumTransactionDispatcher: EthereumTransactionDispatcherAPI

    private var receiveAddress: Single<ReceiveAddress> {
        switch transactionTarget {
        case is ReceiveAddress:
            return .just(transactionTarget as! ReceiveAddress)
        case is CryptoAccount:
            return (transactionTarget as! CryptoAccount).receiveAddress
        default:
            fatalError(
                "Impossible State for Ethereum On Chain Engine: transactionTarget is \(type(of: transactionTarget))"
            )
        }
    }

    // MARK: - Init

    init(
        requireSecondPassword: Bool,
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        feeService: EthereumFeeServiceAPI = resolve(),
        ethereumAccountService: EthereumAccountServiceAPI = resolve(),
        transactionsService: EthereumHistoricalTransactionServiceAPI = resolve(),
        transactionBuildingService: EthereumTransactionBuildingServiceAPI = resolve(),
        ethereumTransactionDispatcher: EthereumTransactionDispatcherAPI = resolve()
    ) {
        self.walletCurrencyService = walletCurrencyService
        self.currencyConversionService = currencyConversionService
        self.feeService = feeService
        self.requireSecondPassword = requireSecondPassword
        self.ethereumAccountService = ethereumAccountService
        self.transactionBuildingService = transactionBuildingService
        self.transactionsService = transactionsService
        self.ethereumTransactionDispatcher = ethereumTransactionDispatcher
        feeCache = CachedValue(
            configuration: .periodic(
                seconds: 90,
                schedulerIdentifier: "EthereumOnChainTransactionEngine"
            )
        )
        feeCache.setFetch(weak: self) { (self) -> Single<EthereumTransactionFee> in
            self.feeService.fees(cryptoCurrency: .coin(.ethereum))
        }
    }

    func assertInputsValid() {
        defaultAssertInputsValid()
        precondition(sourceCryptoCurrency == .coin(.ethereum))
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        Single.zip(
            walletCurrencyService
                .displayCurrency
                .asSingle(),
            availableBalance
        )
        .map { fiatCurrency, availableBalance -> PendingTransaction in
            .init(
                amount: .zero(currency: .coin(.ethereum)),
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

    func doBuildConfirmations(
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        Single
            .zip(
                fiatAmountAndFees(from: pendingTransaction),
                getFeeState(pendingTransaction: pendingTransaction)
            )
            .map(weak: self) { (self, payload) -> PendingTransaction in
                let ((amount, fees), feeState) = payload
                return self.doBuildConfirmations(
                    pendingTransaction: pendingTransaction,
                    amountInFiat: amount.moneyValue,
                    feesInFiat: fees.moneyValue,
                    feeState: feeState
                )
            }
    }

    private func doBuildConfirmations(
        pendingTransaction: PendingTransaction,
        amountInFiat: MoneyValue,
        feesInFiat: MoneyValue,
        feeState: FeeState
    ) -> PendingTransaction {
        let sendDestinationValue = TransactionConfirmation.Model.SendDestinationValue(
            value: pendingTransaction.amount
        )
        let source = TransactionConfirmation.Model.Source(
            value: sourceAccount.label
        )
        let destination = TransactionConfirmation.Model.Destination(
            value: transactionTarget.label
        )
        let feeSelection = TransactionConfirmation.Model.FeeSelection(
            feeState: feeState,
            selectedLevel: pendingTransaction.feeLevel,
            fee: pendingTransaction.feeAmount
        )
        let feedTotal = TransactionConfirmation.Model.FeedTotal(
            amount: pendingTransaction.amount,
            amountInFiat: amountInFiat,
            fee: pendingTransaction.feeAmount,
            feeInFiat: feesInFiat
        )
        return pendingTransaction.update(
            confirmations: [
                .sendDestinationValue(sendDestinationValue),
                .source(source),
                .destination(destination),
                .feeSelection(feeSelection),
                .feedTotal(feedTotal)
            ]
        )
    }

    func update(
        amount: MoneyValue,
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        guard let crypto = amount.cryptoValue else {
            preconditionFailure("Not a `CryptoValue`")
        }
        guard crypto.currencyType == .coin(.ethereum) else {
            preconditionFailure("Not an ethereum value")
        }
        return Single.zip(
            sourceAccount.actionableBalance,
            absoluteFee(with: pendingTransaction.feeLevel)
        )
        .map { values -> PendingTransaction in
            let (actionableBalance, fee) = values
            let available = try actionableBalance - fee.moneyValue
            let zero: MoneyValue = .zero(currency: actionableBalance.currency)
            let max: MoneyValue = try .max(available, zero)
            return pendingTransaction.update(
                amount: amount,
                available: max,
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

    func doValidateAll(
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        sourceAccount.actionableBalance
            .flatMap(weak: self) { (self, actionableBalance) -> Single<PendingTransaction> in
                self.validateSufficientFunds(
                    pendingTransaction: pendingTransaction,
                    actionableBalance: actionableBalance
                )
                .andThen(self.validateNoPendingTransaction())
                .updateTxValidityCompletable(pendingTransaction: pendingTransaction)
            }
    }

    func execute(
        pendingTransaction: PendingTransaction,
        secondPassword: String
    ) -> Single<TransactionResult> {
        guard pendingTransaction.amount.currency == .crypto(.coin(.ethereum)) else {
            fatalError("Not an ethereum value.")
        }

        let address = receiveAddress
            .map(\.address)
            .map { try EthereumAddress(string: $0) }
        return Single.zip(feeCache.valueSingle, address)
            .flatMap { [transactionBuildingService] fee, address -> Single<EthereumTransactionCandidate> in
                transactionBuildingService.buildTransaction(
                    amount: pendingTransaction.amount,
                    to: address,
                    feeLevel: pendingTransaction.feeLevel,
                    fee: fee,
                    contractAddress: nil
                ).single
            }
            .flatMap(weak: self) { (self, candidate) -> Single<EthereumTransactionPublished> in
                self.ethereumTransactionDispatcher
                    .send(transaction: candidate, secondPassword: secondPassword)
            }
            .map(\.transactionHash)
            .map { transactionHash -> TransactionResult in
                .hashed(txHash: transactionHash, amount: pendingTransaction.amount)
            }
    }

    func doRefreshConfirmations(
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        unimplemented()
    }
}

extension EthereumOnChainTransactionEngine {

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

    private func validateSufficientFunds(
        pendingTransaction: PendingTransaction,
        actionableBalance: MoneyValue
    ) -> Completable {
        absoluteFee(with: pendingTransaction.feeLevel)
            .map { [sourceAccount, transactionTarget] fee -> Void in
                guard try pendingTransaction.amount >= pendingTransaction.minSpendable else {
                    throw TransactionValidationFailure(state: .belowMinimumLimit(pendingTransaction.minLimit))
                }
                guard try actionableBalance > fee.moneyValue else {
                    throw TransactionValidationFailure(state: .belowFees(fee.moneyValue, actionableBalance))
                }
                guard try (fee.moneyValue + pendingTransaction.amount) <= actionableBalance else {
                    throw TransactionValidationFailure(
                        state: .insufficientFunds(
                            pendingTransaction.available,
                            pendingTransaction.amount,
                            sourceAccount!.currencyType,
                            transactionTarget!.currencyType
                        )
                    )
                }
            }
            .asCompletable()
    }

    private func absoluteFee(with feeLevel: FeeLevel) -> Single<CryptoValue> {
        let isContract = receiveAddress
            .flatMap(weak: self) { (self, receiveAddress) in
                self.ethereumAccountService
                    .isContract(address: receiveAddress.address)
                    .asSingle()
            }

        return Single
            .zip(feeCache.valueSingle, isContract)
            .map { (fees: EthereumTransactionFee, isContract: Bool) -> CryptoValue in
                let level: EthereumTransactionFee.FeeLevel
                switch feeLevel {
                case .none:
                    fatalError("On chain ETH transactions should never have a 0 fee")
                case .custom:
                    fatalError("Not supported")
                case .priority:
                    level = .priority
                case .regular:
                    level = .regular
                }
                return fees.absoluteFee(with: level, isContract: isContract)
            }
    }

    private func fiatAmountAndFees(
        from pendingTransaction: PendingTransaction
    ) -> Single<(amount: FiatValue, fees: FiatValue)> {
        Single.zip(
            sourceExchangeRatePair,
            .just(pendingTransaction.amount.cryptoValue ?? .zero(currency: .coin(.ethereum))),
            .just(pendingTransaction.feeAmount.cryptoValue ?? .zero(currency: .coin(.ethereum)))
        )
        .map { (quote: $0.0.quote.fiatValue ?? .zero(currency: .USD), amount: $0.1, fees: $0.2) }
        .map { (quote: FiatValue, amount: CryptoValue, fees: CryptoValue) -> (FiatValue, FiatValue) in
            let fiatAmount = amount.convertToFiatValue(exchangeRate: quote)
            let fiatFees = fees.convertToFiatValue(exchangeRate: quote)
            return (fiatAmount, fiatFees)
        }
        .map { (amount: $0.0, fees: $0.1) }
    }

    private var sourceExchangeRatePair: Single<MoneyValuePair> {
        walletCurrencyService
            .displayCurrency
            .flatMap { [sourceAsset, currencyConversionService] fiatCurrency in
                currencyConversionService
                    .conversionRate(from: sourceAsset, to: fiatCurrency.currencyType)
                    .map { MoneyValuePair(base: .one(currency: sourceAsset), quote: $0) }
            }
            .asSingle()
    }
}
