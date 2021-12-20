// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift
import RxToolKit
import ToolKit

public final class InterestWithdrawTradingTransationEngine: InterestTransactionEngine {

    // MARK: - InterestTransactionEngine

    public var minimumDepositLimits: Single<FiatValue> {
        unimplemented()
    }

    // MARK: - TransactionEngine

    public let walletCurrencyService: FiatCurrencyServiceAPI
    public let currencyConversionService: CurrencyConversionServiceAPI
    public var askForRefreshConfirmation: AskForRefreshConfirmation!
    public var sourceAccount: BlockchainAccount!
    public var transactionTarget: TransactionTarget!

    public var requireSecondPassword: Bool

    // MARK: - Private Properties

    private var availableBalance: Single<MoneyValue> {
        sourceAccount
            .balance
    }

    private var minimumLimit: Single<MoneyValue> {
        feeCache
            .fetchValue
            .map(\.[minimumAmount: sourceAsset])
    }

    private var fee: Single<MoneyValue> {
        feeCache
            .fetchValue
            .map(\.[fee: sourceAsset])
    }

    private var interestAccountLimits: Single<InterestAccountLimits> {
        walletCurrencyService
            .displayCurrency
            .flatMap { [accountLimitsRepository, sourceAsset] fiatCurrency in
                accountLimitsRepository
                    .fetchInterestAccountLimitsForCryptoCurrency(
                        sourceAsset.cryptoCurrency!,
                        fiatCurrency: fiatCurrency
                    )
            }
            .asSingle()
    }

    private let feeCache: CachedValue<CustodialTransferFee>
    private let accountTransferRepository: InterestAccountTransferRepositoryAPI
    /// Used for fetching fees and limits for interest.
    private let transferRepository: CustodialTransferRepositoryAPI
    private let accountLimitsRepository: InterestAccountLimitsRepositoryAPI

    // MARK: - Init

    init(
        requireSecondPassword: Bool,
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        accountLimitsRepository: InterestAccountLimitsRepositoryAPI = resolve(),
        transferRepository: CustodialTransferRepositoryAPI = resolve(),
        accountTransferRepository: InterestAccountTransferRepositoryAPI = resolve()
    ) {
        self.accountTransferRepository = accountTransferRepository
        self.walletCurrencyService = walletCurrencyService
        self.requireSecondPassword = requireSecondPassword
        self.currencyConversionService = currencyConversionService
        self.accountLimitsRepository = accountLimitsRepository
        self.transferRepository = transferRepository
        feeCache = CachedValue(
            configuration: .periodic(
                seconds: 20,
                schedulerIdentifier: "InterestWithdrawTradingTransationEngine"
            )
        )
        feeCache.setFetch(weak: self) { (self) -> Single<CustodialTransferFee> in
            self.transferRepository
                .feesAndLimitsForInterest()
                .asSingle()
        }
    }

    public func assertInputsValid() {
        precondition(sourceAccount is InterestAccount)
        precondition(transactionTarget is CryptoAccount)
        precondition(transactionTarget is TradingAccount)
        precondition(sourceAsset == (transactionTarget as! CryptoAccount).asset)
    }

    public func initializeTransaction()
        -> Single<PendingTransaction>
    {
        Single.zip(
            walletCurrencyService
                .displayCurrency
                .asSingle(),
            fee,
            availableBalance,
            minimumLimit,
            interestAccountLimits
                .map(\.maxWithdrawalAmount)
                .map(\.moneyValue)
        )
        .map { [sourceAsset] fiatCurrency, fee, balance, minimum, maximum -> PendingTransaction in
            PendingTransaction(
                amount: .zero(currency: sourceAsset),
                available: balance,
                feeAmount: fee,
                feeForFullAvailable: .zero(currency: sourceAsset),
                feeSelection: .empty(asset: sourceAsset),
                selectedFiatCurrency: fiatCurrency,
                minimumLimit: minimum,
                maximumLimit: maximum
            )
        }
    }

    public func doBuildConfirmations(
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        let source = sourceAccount.label
        let destination = transactionTarget.label
        return fiatAmountAndFees(from: pendingTransaction)
            .map { fiatAmount, fiatFees -> PendingTransaction in
                pendingTransaction
                    .update(
                        confirmations: [
                            .source(.init(value: source)),
                            .destination(.init(value: destination)),
                            .feedTotal(
                                .init(
                                    amount: pendingTransaction.amount,
                                    amountInFiat: fiatAmount.moneyValue,
                                    fee: pendingTransaction.feeAmount,
                                    feeInFiat: fiatFees.moneyValue
                                )
                            ),
                            .total(.init(total: pendingTransaction.amount))
                        ]
                    )
            }
    }

    public func update(
        amount: MoneyValue,
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        availableBalance
            .map { balance in
                pendingTransaction
                    .update(
                        amount: amount,
                        available: balance
                    )
            }
    }

    public func validateAmount(
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        availableBalance
            .flatMapCompletable(weak: self) { (self, balance) in
                self.checkIfAvailableBalanceIsSufficient(
                    pendingTransaction,
                    balance: balance
                )
                .andThen(
                    self.checkIfAmountIsBelowMinimumLimit(
                        pendingTransaction
                    )
                )
            }
            .updateTxValidityCompletable(
                pendingTransaction: pendingTransaction
            )
    }

    public func doValidateAll(
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        validateAmount(pendingTransaction: pendingTransaction)
    }

    public func execute(
        pendingTransaction: PendingTransaction,
        secondPassword: String
    ) -> Single<TransactionResult> {
        accountTransferRepository
            .createInterestAccountCustodialWithdraw(pendingTransaction.amount)
            .mapError { _ in
                TransactionValidationFailure(state: .unknownError)
            }
            .map { _ in
                TransactionResult.unHashed(amount: pendingTransaction.amount)
            }
            .asSingle()
    }

    public func doPostExecute(
        transactionResult: TransactionResult
    ) -> Completable {
        transactionTarget
            .onTxCompleted(transactionResult)
    }

    public func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction> {
        .just(pendingTransaction)
    }
}
