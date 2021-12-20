// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

public protocol TransactionOrder {
    var identifier: String { get }
}

public protocol TransactionEngine: AnyObject {

    typealias AskForRefreshConfirmation = (_ revalidate: Bool) -> Completable

    /// Used for fetching the wallet's default currency
    var walletCurrencyService: FiatCurrencyServiceAPI { get }
    /// Used to convert amounts in different currencies
    var currencyConversionService: CurrencyConversionServiceAPI { get }

    /// Does this engine accept fiat input amounts
    var canTransactFiat: Bool { get }
    /// askForRefreshConfirmation: Must be set by TransactionProcessor
    var askForRefreshConfirmation: AskForRefreshConfirmation! { get set }

    /// The account the user is transacting from
    var sourceAccount: BlockchainAccount! { get set }

    var transactionTarget: TransactionTarget! { get set }
    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> { get }
    var requireSecondPassword: Bool { get }
    // If the source and target assets are not the same this MAY return a stream of the exchange rates
    // between them. Or it may simply complete.
    var transactionExchangeRatePair: Observable<MoneyValuePair> { get }

    func assertInputsValid()
    func start(
        sourceAccount: BlockchainAccount,
        transactionTarget: TransactionTarget,
        askForRefreshConfirmation: @escaping AskForRefreshConfirmation
    )
    func stop(pendingTransaction: PendingTransaction)
    func restart(
        transactionTarget: TransactionTarget,
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction>

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction>

    /// Implementation interface:
    /// Call this first to initialise the processor. Construct and initialise a pendingTx object.
    func initializeTransaction() -> Single<PendingTransaction>

    /// Update the transaction with a new amount. This method should check balances, calculate fees and
    /// Return a new PendingTx with the state updated for the UI to update. The pending Tx will
    /// be passed to validate after this call.
    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction>

    /// Process any `TransactionConfirmation` updates, if required. The default just replaces the option and returns
    /// the updated pendingTx. Subclasses may want to, eg, update amounts on fee changes etc
    func doOptionUpdateRequest(
        pendingTransaction: PendingTransaction,
        newConfirmation: TransactionConfirmation
    ) -> Single<PendingTransaction>

    /// Check the tx is complete, well formed and possible. If it is, set pendingTx to CAN_EXECUTE
    /// Else set it to the appropriate error, and then return the updated PendingTx
    func validateAmount(pendingTransaction: PendingTransaction) -> Single<PendingTransaction>

    /// Check the tx is complete, well formed and possible. If it is, set pendingTx to CAN_EXECUTE
    /// Else set it to the appropriate error, and then return the updated PendingTx
    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction>

    /// Create a `TransactionOrder` for the pending transaction. Not all transaction types require an order. Return a `nil` order if that's the case.
    /// - Parameter pendingTransaction: The pending transaction so far.
    func createOrder(pendingTransaction: PendingTransaction) -> Single<TransactionOrder?>

    /// If a `TransactionOrder` was created, the user can cancel it. When an order needs to be cancelled, this method gets called.
    /// - Parameter identifier: The identifier of the order to be cancelled.
    func cancelOrder(with identifier: String) -> Single<Void>

    /// Execute the transaction, it will have been validated before this is called, so the expectation is that it will succeed.
    /// - Note:This method should be implemented by `TransactionEngine`s that don't require the creation of an order.
    /// - Parameters:
    ///   - pendingTransaction: The pending transaction so far.
    ///   - secondPassword: The second password or a empty string if not needed.
    func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult>

    /// Execute the transaction, it will have been validated before this is called, so the expectation is that it will succeed.
    /// - Note: This method is defaulted to call `execute(pendingTransaction:secondPassword:)`.
    /// - Parameters:
    ///   - pendingTransaction: The pending transaction so far
    ///   - pendingOrder: The pending order if one was created by `createOrder`.
    ///   - secondPassword: The second password or an empty string if not needed.
    func execute(
        pendingTransaction: PendingTransaction,
        pendingOrder: TransactionOrder?,
        secondPassword: String
    ) -> Single<TransactionResult>

    /// Action to be executed once the transaction has been executed, it will have been validated before this is called, so the expectation
    /// is that it will succeed.
    func doPostExecute(transactionResult: TransactionResult) -> Completable

    /// Action to be executed when confirmations have been built and we want to start checking for updates on them
    func startConfirmationsUpdate(pendingTransaction: PendingTransaction) -> Single<PendingTransaction>

    /// Update the selected fee level of this Tx.
    /// This should check & update balances etc.
    /// This is only called when the user is applying a custom fee.
    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction>

    func doRefreshConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction>
}

extension TransactionEngine {

    public var transactionExchangeRatePair: Observable<MoneyValuePair> {
        .empty()
    }

    public var sourceAsset: CurrencyType {
        guard let account = sourceAccount as? SingleAccount else {
            fatalError("Expected a SingleAccount: \(String(describing: sourceAccount))")
        }
        return account.currencyType
    }

    public var sourceCryptoCurrency: CryptoCurrency {
        guard let crypto = sourceAsset.cryptoCurrency else {
            fatalError("Expected a CryptoCurrency type: \(sourceAsset)")
        }
        return crypto
    }

    public var canTransactFiat: Bool { false }

    public func stop(pendingTransaction: PendingTransaction) {}

    public func start(
        sourceAccount: BlockchainAccount,
        transactionTarget: TransactionTarget,
        askForRefreshConfirmation: @escaping (_ revalidate: Bool) -> Completable
    ) {
        self.sourceAccount = sourceAccount
        self.transactionTarget = transactionTarget
        self.askForRefreshConfirmation = askForRefreshConfirmation
    }

    public func restart(
        transactionTarget: TransactionTarget,
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        defaultRestart(transactionTarget: transactionTarget, pendingTransaction: pendingTransaction)
    }

    public func defaultRestart(
        transactionTarget: TransactionTarget,
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        self.transactionTarget = transactionTarget
        return .just(pendingTransaction)
    }

    public func doRefreshConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        .just(pendingTransaction)
    }

    public func doOptionUpdateRequest(
        pendingTransaction: PendingTransaction,
        newConfirmation: TransactionConfirmation
    ) -> Single<PendingTransaction> {
        defaultDoOptionUpdateRequest(pendingTransaction: pendingTransaction, newConfirmation: newConfirmation)
    }

    public func defaultDoOptionUpdateRequest(
        pendingTransaction: PendingTransaction,
        newConfirmation: TransactionConfirmation
    ) -> Single<PendingTransaction> {
        .just(pendingTransaction.insert(confirmation: newConfirmation))
    }

    public func startConfirmationsUpdate(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        .just(pendingTransaction)
    }

    public func createOrder(pendingTransaction: PendingTransaction) -> Single<TransactionOrder?> {
        .just(nil)
    }

    public func cancelOrder(with identifier: String) -> Single<Void> {
        .just(())
    }

    public func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult> {
        // swiftlint:disable:next line_length
        unimplemented("Override this method in your Engine implementation. If you need to execute an order, override \(String(describing: execute(pendingTransaction:pendingOrder:secondPassword:))) instead")
    }

    public func execute(
        pendingTransaction: PendingTransaction,
        pendingOrder: TransactionOrder?,
        secondPassword: String
    ) -> Single<TransactionResult> {
        execute(pendingTransaction: pendingTransaction, secondPassword: secondPassword)
    }

    public func doPostExecute(
        transactionResult: TransactionResult
    ) -> Completable {
        sourceAccount.invalidateAccountBalance()
        if let target = transactionTarget as? BlockchainAccount {
            target.invalidateAccountBalance()
        }
        return transactionTarget
            .onTxCompleted(transactionResult)
    }
}

private struct TransactionValidationConversionRates {
    let amountToWalletRate: MoneyValue
    let feeToWalletRate: MoneyValue
    let sourceToWalletRate: MoneyValue
    let limitsToAmountRate: MoneyValue
}

extension TransactionEngine {

    public func validateAmount(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        guard let sourceAccount = sourceAccount, transactionTarget != nil else {
            return .error(TransactionValidationFailure(state: .uninitialized))
        }
        // NOTE: Convert amounts for comparison from fiat to crypto or vice versa, but never crypto -> crypto as this is not fully supported yet.
        return fetchAmountConversionRates(for: pendingTransaction)
            .mapError { error -> Error in
                error // map to generic Error for zipping with balance
            }
            .zip(sourceAccount.balancePublisher)
            .asSingle()
            .map { [weak self] conversionRates, sourceBalance -> Void in
                let convertedBalance = sourceBalance.convert(using: conversionRates.sourceToWalletRate)
                let convertedFee = pendingTransaction.feeAmount.convert(using: conversionRates.feeToWalletRate)
                guard try convertedBalance >= convertedFee else {
                    throw TransactionValidationFailure(state: .belowFees(convertedFee, convertedBalance))
                }

                let amount = pendingTransaction.amount
                let limits = pendingTransaction.normalizedLimits.convert(using: conversionRates.limitsToAmountRate)
                let availableBalanceInWalletCurrency = try convertedBalance - convertedFee
                let availableBalance = availableBalanceInWalletCurrency.convert(
                    usingInverse: conversionRates.amountToWalletRate,
                    currencyType: amount.currencyType
                )
                try self?.validate(amount, hasAmountUpToSourceLimit: availableBalance)
                try self?.validate(amount, isWithin: limits, amountToWalletRate: conversionRates.amountToWalletRate)
            }
            .asCompletable()
            .updateTxValidityCompletable(pendingTransaction: pendingTransaction)
    }

    private func fetchAmountConversionRates(
        for pendingTransaction: PendingTransaction
    ) -> AnyPublisher<TransactionValidationConversionRates, PriceServiceError> {
        walletCurrencyService
            .tradingCurrencyPublisher
            .setFailureType(to: PriceServiceError.self)
            .flatMap { [currencyConversionService, sourceAsset] walletCurrency in
                currencyConversionService.conversionRate(
                    from: pendingTransaction.amount.currencyType,
                    to: walletCurrency.currencyType
                )
                .zip(
                    currencyConversionService.conversionRate(
                        from: pendingTransaction.feeAmount.currencyType,
                        to: walletCurrency.currencyType
                    ),
                    currencyConversionService.conversionRate(
                        from: sourceAsset,
                        to: walletCurrency.currencyType
                    ),
                    currencyConversionService.conversionRate(
                        from: pendingTransaction.normalizedLimits.currencyType,
                        to: pendingTransaction.amount.currencyType
                    )
                )
            }
            .map { conversionRates in
                let (amountToWalletRate, feeToWalletRate, sourceToWallet, limitsToAmountRate) = conversionRates
                return TransactionValidationConversionRates(
                    amountToWalletRate: amountToWalletRate,
                    feeToWalletRate: feeToWalletRate,
                    sourceToWalletRate: sourceToWallet,
                    limitsToAmountRate: limitsToAmountRate
                )
            }
            .eraseToAnyPublisher()
    }

    private func validate(
        _ amount: MoneyValue,
        isWithin limits: TransactionLimits,
        amountToWalletRate: MoneyValue
    ) throws {
        let minLimit = limits.minimum ?? .zero(currency: limits.currencyType)
        guard try amount >= minLimit else {
            throw TransactionValidationFailure(state: .belowMinimumLimit(minLimit))
        }

        guard let maxLimit = limits.maximum else {
            return
        }

        guard try amount <= maxLimit else {
            if sourceAccount is LinkedBankAccount {
                throw TransactionValidationFailure(
                    state: .overMaximumSourceLimit(
                        maxLimit.convert(using: amountToWalletRate),
                        sourceAccount.label,
                        amount
                    )
                )
            }
            throw TransactionValidationFailure(
                state: .overMaximumPersonalLimit(
                    limits.effectiveLimit ?? EffectiveLimit(timeframe: .single, value: maxLimit),
                    maxLimit.convert(using: amountToWalletRate),
                    limits.suggestedUpgrade
                )
            )
        }
    }

    private func validate(_ amount: MoneyValue, hasAmountUpToSourceLimit limit: MoneyValue) throws {
        guard (sourceAccount is LinkedBankAccount) == false else {
            // bank accounts have no balance to us, so nothing to there's validate against
            return
        }
        guard try amount <= limit else {
            if let source = sourceAccount as? PaymentMethodAccount, !source.paymentMethod.type.isFunds {
                throw TransactionValidationFailure(
                    state: .overMaximumSourceLimit(limit, sourceAccount.label, amount)
                )
            }
            throw TransactionValidationFailure(
                state: .insufficientFunds(
                    limit,
                    amount,
                    sourceAccount.currencyType,
                    transactionTarget.currencyType
                )
            )
        }
    }
}
