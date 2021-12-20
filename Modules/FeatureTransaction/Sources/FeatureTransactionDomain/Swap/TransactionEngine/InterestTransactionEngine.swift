// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

public protocol InterestTransactionEngine: TransactionEngine {

    // MARK: - Properties

    var minimumDepositLimits: Single<FiatValue> { get }
}

extension InterestTransactionEngine {

    // MARK: - Public Functions

    public func modifyEngineConfirmations(
        _ pendingTransaction: PendingTransaction,
        termsChecked: Bool,
        agreementChecked: Bool
    ) -> PendingTransaction {
        pendingTransaction
            .insert(
                confirmation: .termsOfService(
                    .init(
                        value: termsChecked,
                        type: .agreementInterestTandC
                    )
                )
            )
            .insert(
                confirmation: .transferAgreement(
                    .init(
                        value: agreementChecked,
                        type: .agreementInterestTransfer
                    )
                )
            )
    }

    public func checkIfAmountIsBelowMinimumLimit(_ pendingTransaction: PendingTransaction) -> Completable {
        Completable.fromCallable {
            let minimum = pendingTransaction.minLimit
            guard try pendingTransaction.amount >= minimum else {
                throw TransactionValidationFailure(state: .belowMinimumLimit(minimum))
            }
        }
    }

    public func checkIfAvailableBalanceIsSufficient(
        _ pendingTransaction: PendingTransaction,
        balance: MoneyValue
    ) -> Completable {
        Completable.fromCallable { [sourceAccount, transactionTarget] in
            guard try pendingTransaction.amount <= balance else {
                throw TransactionValidationFailure(
                    state: .insufficientFunds(
                        balance,
                        pendingTransaction.amount,
                        sourceAccount!.currencyType,
                        transactionTarget!.currencyType
                    )
                )
            }
        }
    }

    public func getTermsOptionValueFromPendingTransaction(
        _ pendingTransaction: PendingTransaction
    ) -> Bool {
        pendingTransaction
            .termsOptionValue
    }

    public func getTransferAgreementOptionValueFromPendingTransaction(
        _ pendingTransaction: PendingTransaction
    ) -> Bool {
        pendingTransaction
            .agreementOptionValue
    }

    public func fiatAmountAndFees(
        from pendingTransaction: PendingTransaction
    ) -> Single<(amount: FiatValue, fees: FiatValue)> {
        Single.zip(
            sourceExchangeRatePair,
            .just(pendingTransaction.amount.cryptoValue ?? .zero(currency: sourceCryptoCurrency)),
            .just(pendingTransaction.feeAmount.cryptoValue ?? .zero(currency: sourceCryptoCurrency))
        )
        .map { (quote: $0.0.quote.fiatValue ?? .zero(currency: .USD), amount: $0.1, fees: $0.2) }
        .map { (quote: FiatValue, amount: CryptoValue, fees: CryptoValue) -> (FiatValue, FiatValue) in
            let fiatAmount = amount.convertToFiatValue(exchangeRate: quote)
            let fiatFees = fees.convertToFiatValue(exchangeRate: quote)
            return (fiatAmount, fiatFees)
        }
        .map { (amount: $0.0, fees: $0.1) }
    }

    // MARK: - Internal

    var sourceExchangeRatePair: Single<MoneyValuePair> {
        walletCurrencyService
            .displayCurrency
            .asSingle()
            .flatMap { [currencyConversionService, sourceAsset] fiatCurrency -> Single<MoneyValuePair> in
                currencyConversionService
                    .conversionRate(from: sourceAsset, to: fiatCurrency.currencyType)
                    .asSingle()
                    .map { MoneyValuePair(base: .one(currency: sourceAsset), quote: $0) }
            }
    }
}

extension InterestTransactionEngine {

    public var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        sourceExchangeRatePair
            .map { pair -> TransactionMoneyValuePairs in
                TransactionMoneyValuePairs(
                    source: pair,
                    destination: pair
                )
            }
            .asObservable()
    }
}
