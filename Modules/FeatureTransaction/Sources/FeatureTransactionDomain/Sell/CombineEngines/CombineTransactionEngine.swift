// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError
import PlatformKit
import ToolKit

public protocol CombineTransactionEngine: AnyObject {

    typealias AskForRefreshConfirmation = (_ revalidate: Bool) -> AnyPublisher<Void, Error>

    /// Does this engine accept fiat input amounts
    var canTransactFiat: Bool { get }
    /// askForRefreshConfirmation: Must be set by TransactionProcessor
    var askForRefreshConfirmation: AskForRefreshConfirmation { get set }

    /// The account the user is transacting from
    var sourceAccount: BlockchainAccount! { get set }

    var transactionTarget: TransactionTarget! { get set }
    var fiatExchangeRatePairs: AnyPublisher<TransactionMoneyValuePairs, Error> { get }
    var requireSecondPassword: Bool { get }

    /// If the source and target assets are not the same this MAY return a stream of the exchange rates
    /// between them. Or it may simply complete.
    var transactionExchangeRatePair: AnyPublisher<MoneyValuePair, Error> { get }

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
    ) -> AnyPublisher<PendingTransaction, Error>

    func doBuildConfirmations(
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, NabuNetworkError>

    /// Implementation interface:
    /// Call this first to initialise the processor. Construct and initialise a pendingTx object.
    func initializeTransaction() -> AnyPublisher<PendingTransaction, Error>

    /// Update the transaction with a new amount. This method should check balances, calculate fees and
    /// Return a new PendingTx with the state updated for the UI to update. The pending Tx will
    /// be passed to validate after this call.
    func update(
        amount: MoneyValue,
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error>

    /// Process any `TransactionConfirmation` updates, if required. The default just replaces the option and returns
    /// the updated pendingTx. Subclasses may want to, eg, update amounts on fee changes etc
    func doOptionUpdateRequest(
        pendingTransaction: PendingTransaction,
        newConfirmation: TransactionConfirmation
    ) -> AnyPublisher<PendingTransaction, Error>

    /// Check the tx is complete, well formed and possible. If it is, set pendingTx to CAN_EXECUTE
    /// Else set it to the appropriate error, and then return the updated PendingTx
    func validateAmount(
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error>

    /// Check the tx is complete, well formed and possible. If it is, set pendingTx to CAN_EXECUTE
    /// Else set it to the appropriate error, and then return the updated PendingTx
    func doValidateAll(
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error>

    /// Execute the transaction, it will have been validated before this is called, so the expectation
    /// is that it will succeed.
    /// - Parameter secondPassword: The second password or a empty string if not needed.
    func execute(
        pendingTransaction: PendingTransaction,
        secondPassword: String
    ) -> AnyPublisher<TransactionResult, Error>

    /// Action to be executed once the transaction has been executed, it will have been validated before this is called, so the expectation
    /// is that it will succeed.
    func doPostExecute(
        transactionResult: TransactionResult
    ) -> AnyPublisher<Void, Error>

    /// Action to be executed when confirmations have been built and we want to start checking for updates on them
    func startConfirmationsUpdate(
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error>

    /// Update the selected fee level of this Tx.
    /// This should check & update balances etc.
    /// This is only called when the user is applying a custom fee.
    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> AnyPublisher<PendingTransaction, Error>

    func doRefreshConfirmations(
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error>
}

extension CombineTransactionEngine {

    public var transactionExchangeRatePair: AnyPublisher<MoneyValuePair, Error> {
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
        askForRefreshConfirmation: @escaping (_ revalidate: Bool) -> AnyPublisher<Void, Error>
    ) {
        self.sourceAccount = sourceAccount
        self.transactionTarget = transactionTarget
        self.askForRefreshConfirmation = askForRefreshConfirmation
    }

    public func restart(
        transactionTarget: TransactionTarget,
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error> {
        defaultRestart(transactionTarget: transactionTarget, pendingTransaction: pendingTransaction)
    }

    public func defaultRestart(
        transactionTarget: TransactionTarget,
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error> {
        self.transactionTarget = transactionTarget
        return .just(pendingTransaction)
    }

    public func doRefreshConfirmations(
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error> {
        .just(pendingTransaction)
    }

    public func doOptionUpdateRequest(
        pendingTransaction: PendingTransaction,
        newConfirmation: TransactionConfirmation
    ) -> AnyPublisher<PendingTransaction, Error> {
        defaultDoOptionUpdateRequest(pendingTransaction: pendingTransaction, newConfirmation: newConfirmation)
    }

    public func defaultDoOptionUpdateRequest(
        pendingTransaction: PendingTransaction,
        newConfirmation: TransactionConfirmation
    ) -> AnyPublisher<PendingTransaction, Error> {
        .just(pendingTransaction.insert(confirmation: newConfirmation))
    }

    public func startConfirmationsUpdate(
        pendingTransaction: PendingTransaction
    ) -> AnyPublisher<PendingTransaction, Error> {
        .just(pendingTransaction)
    }
}
