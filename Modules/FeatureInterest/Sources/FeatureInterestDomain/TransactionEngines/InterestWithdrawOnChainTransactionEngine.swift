// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift
import RxToolKit
import ToolKit

public final class InterestWithdrawOnChainTransactionEngine: OnChainTransactionEngine, InterestTransactionEngine {

    // MARK: - InterestTransactionEngine

    public var minimumDepositLimits: Single<FiatValue> {
        unimplemented()
    }

    // MARK: - OnChainTransactionEngine

    public let walletCurrencyService: FiatCurrencyServiceAPI
    public let currencyConversionService: CurrencyConversionServiceAPI
    public var askForRefreshConfirmation: AskForRefreshConfirmation!

    public var requireSecondPassword: Bool

    public var transactionTarget: TransactionTarget!
    public var sourceAccount: BlockchainAccount!

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
    private let transferRepository: CustodialTransferRepositoryAPI
    private let interestAccountWithdrawRepository: InterestAccountWithdrawRepositoryAPI
    private let accountLimitsRepository: InterestAccountLimitsRepositoryAPI

    // MARK: - Init

    init(
        requireSecondPassword: Bool,
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        accountLimitsRepository: InterestAccountLimitsRepositoryAPI = resolve(),
        transferRepository: CustodialTransferRepositoryAPI = resolve(),
        interestAccountWithdrawRepository: InterestAccountWithdrawRepositoryAPI = resolve()
    ) {
        self.requireSecondPassword = requireSecondPassword
        self.walletCurrencyService = walletCurrencyService
        self.currencyConversionService = currencyConversionService
        self.accountLimitsRepository = accountLimitsRepository
        self.transferRepository = transferRepository
        self.interestAccountWithdrawRepository = interestAccountWithdrawRepository
        feeCache = CachedValue(
            configuration: .periodic(
                seconds: 20,
                schedulerIdentifier: "InterestWithdrawOnChainTransactionEngine"
            )
        )
        feeCache.setFetch(weak: self) { (self) -> Single<CustodialTransferFee> in
            self.transferRepository
                .feesAndLimitsForInterest()
                .asSingle()
        }
    }

    public func assertInputsValid() {
        precondition(transactionTarget is CryptoReceiveAddress)
        precondition(sourceAccount is InterestAccount)
        precondition(sourceAsset == transactionTarget.currencyType)
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

    public func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
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
                            // TODO: Account for memo if the transactionTarget
                            // has a memo.
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
        guard let receiveAddress = transactionTarget as? CryptoReceiveAddress else {
            return .error(TransactionValidationFailure(state: .unknownError))
        }
        let address = addMemoIfNeeded(
            receiveAddress: receiveAddress.address,
            memo: receiveAddress.memo
        )
        return interestAccountWithdrawRepository
            .createInterestAccountWithdrawal(
                pendingTransaction.amount,
                address: address,
                currencyCode: sourceAsset.code
            )
            .map { _ in
                TransactionResult.unHashed(amount: pendingTransaction.amount)
            }
            .asSingle()
    }

    // MARK: - Private Functions

    private func addMemoIfNeeded(receiveAddress: String, memo: String?) -> String {
        if let memo = memo {
            return receiveAddress + ":\(memo)"
        }
        return receiveAddress
    }
}
