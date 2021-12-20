// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

final class FiatWithdrawalTransactionEngine: TransactionEngine {

    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        .empty()
    }

    let walletCurrencyService: FiatCurrencyServiceAPI
    let currencyConversionService: CurrencyConversionServiceAPI

    let requireSecondPassword: Bool = false
    let canTransactFiat: Bool = true
    var askForRefreshConfirmation: ((Bool) -> Completable)!
    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!

    var sourceTradingAccount: FiatAccount! {
        sourceAccount as? FiatAccount
    }

    var target: LinkedBankAccount { transactionTarget as! LinkedBankAccount }
    var targetAsset: FiatCurrency { target.fiatCurrency }
    var sourceAsset: FiatCurrency { sourceTradingAccount.fiatCurrency }

    // MARK: - Private Properties

    private let fiatWithdrawRepository: FiatWithdrawRepositoryAPI
    private let withdrawalService: WithdrawalServiceAPI

    // MARK: - Init

    init(
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        withdrawalService: WithdrawalServiceAPI = resolve(),
        fiatWithdrawRepository: FiatWithdrawRepositoryAPI = resolve()
    ) {
        self.walletCurrencyService = walletCurrencyService
        self.withdrawalService = withdrawalService
        self.currencyConversionService = currencyConversionService
        self.fiatWithdrawRepository = fiatWithdrawRepository
    }

    // MARK: - TransactionEngine

    func assertInputsValid() {
        precondition(sourceAccount is FiatAccount)
        precondition(transactionTarget is LinkedBankAccount)
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        Single.zip(
            sourceAccount.actionableBalance,
            withdrawalService.withdrawFeeAndLimit(
                for: target.fiatCurrency,
                paymentMethodType: target.paymentType
            ),
            walletCurrencyService
                .displayCurrency
                .asSingle()
        )
        .map { [sourceAsset] values -> PendingTransaction in
            let (actionableBalance, feeAndLimit, fiatCurrency) = values
            let zero: MoneyValue = .zero(currency: sourceAsset)
            return PendingTransaction(
                amount: zero,
                available: actionableBalance,
                feeAmount: feeAndLimit.fee.moneyValue,
                feeForFullAvailable: zero,
                feeSelection: .init(
                    selectedLevel: .none,
                    availableLevels: []
                ),
                selectedFiatCurrency: fiatCurrency,
                minimumLimit: feeAndLimit.minLimit.moneyValue,
                maximumLimit: feeAndLimit.maxLimit?.moneyValue ?? actionableBalance
            )
        }
    }

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        .just(pendingTransaction
            .update(
                confirmations: [
                    .source(.init(value: sourceAccount.label)),
                    .destination(.init(value: target.label)),
                    .transactionFee(.init(fee: pendingTransaction.feeAmount)),
                    .arrivalDate(.default),
                    .total(.init(total: pendingTransaction.amount))
                ]
            )
        )
    }

    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        .just(pendingTransaction.update(amount: amount))
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmount(pendingTransaction: pendingTransaction)
            .updateTxValiditySingle(pendingTransaction: pendingTransaction)
    }

    func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult> {
        target
            .receiveAddress
            .map(\.address)
            .flatMapCompletable { [fiatWithdrawRepository] address -> Completable in
                fiatWithdrawRepository
                    .createWithdrawOrder(id: address, amount: pendingTransaction.amount)
                    .asObservable()
                    .ignoreElements()
                    .asCompletable()
            }
            .flatMapSingle {
                .just(TransactionResult.unHashed(amount: pendingTransaction.amount))
            }
    }

    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction> {
        precondition(pendingTransaction.feeSelection.availableLevels.contains(level))
        return .just(pendingTransaction)
    }

    // MARK: - Private Functions

    private func validateAmountCompletable(pendingTransaction: PendingTransaction) -> Completable {
        Completable.fromCallable { [sourceAccount, transactionTarget] in
            let minLimit = pendingTransaction.minLimit
            let maxLimit = pendingTransaction.maxLimit
            guard try pendingTransaction.amount >= minLimit else {
                throw TransactionValidationFailure(state: .belowMinimumLimit(minLimit))
            }
            guard try pendingTransaction.amount <= maxLimit else {
                throw TransactionValidationFailure(
                    state: .overMaximumPersonalLimit(
                        EffectiveLimit(timeframe: .daily, value: pendingTransaction.maxSpendable),
                        maxLimit,
                        nil
                    )
                )
            }
            guard try pendingTransaction.available >= pendingTransaction.amount else {
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
    }
}
