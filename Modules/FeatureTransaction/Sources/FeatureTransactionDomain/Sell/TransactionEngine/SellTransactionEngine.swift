// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import MoneyKit
import PlatformKit
import RxSwift

protocol SellTransactionEngine: TransactionEngine {

    var orderDirection: OrderDirection { get }
    var quotesEngine: SwapQuotesEngine { get }
    var transactionLimitsService: TransactionLimitsServiceAPI { get }
    var orderQuoteRepository: OrderQuoteRepositoryAPI { get }
    var orderCreationRepository: OrderCreationRepositoryAPI { get }
}

extension SellTransactionEngine {

    var target: FiatAccount {
        transactionTarget as! FiatAccount
    }

    var sourceAsset: CryptoCurrency { sourceCryptoCurrency }
    var targetAsset: FiatCurrency { target.fiatCurrency }

    var pair: OrderPair {
        OrderPair(
            sourceCurrencyType: sourceAsset.currencyType,
            destinationCurrencyType: target.fiatCurrency.currencyType
        )
    }

    // MARK: - TransactionEngine

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmount(pendingTransaction: pendingTransaction)
    }

    func validateUpdateAmount(_ amount: MoneyValue) -> Single<MoneyValue> {
        .just(amount)
    }

    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        Single.zip(sourceExchangeRatePair, destinationExchangeRatePair)
            .map { source, destination -> TransactionMoneyValuePairs in
                TransactionMoneyValuePairs(
                    source: source,
                    destination: destination
                )
            }
            .asObservable()
    }

    var sourceExchangeRatePair: Single<MoneyValuePair> {
        transactionExchangeRatePair
            .take(1)
            .asSingle()
    }

    private var destinationExchangeRatePair: Single<MoneyValuePair> {
        transactionExchangeRatePair
            .map(\.inverseExchangeRate)
            .take(1)
            .asSingle()
    }

    var transactionExchangeRatePair: Observable<MoneyValuePair> {
        quotesEngine
            .getRate(
                direction: orderDirection,
                pair: .init(
                    sourceCurrencyType: sourceAsset,
                    destinationCurrencyType: target.currencyType
                )
            )
            .map { [target] pricedQuote -> MoneyValue in
                MoneyValue(amount: pricedQuote.price, currency: target.currencyType)
            }
            .map { [sourceAsset] rate -> MoneyValuePair in
                MoneyValuePair(base: .one(currency: sourceAsset), exchangeRate: rate)
            }
    }

    func updateLimits(
        pendingTransaction: PendingTransaction,
        pricedQuote: PricedQuote
    ) -> Single<PendingTransaction> {
        let limitsPublisher = transactionLimitsService.fetchLimits(
            source: LimitsAccount(
                currency: sourceAsset.currencyType,
                accountType: orderDirection.isFromCustodial ? .custodial : .nonCustodial
            ),
            destination: LimitsAccount(
                currency: targetAsset.currencyType,
                accountType: orderDirection.isToCustodial ? .custodial : .nonCustodial
            ),
            product: .sell(orderDirection)
        )
        return limitsPublisher
            .asSingle()
            .map { transactionLimits -> PendingTransaction in
                var pendingTransaction = pendingTransaction
                pendingTransaction.limits = try transactionLimits.update(with: pricedQuote)
                return pendingTransaction
            }
    }

    func clearConfirmations(pendingTransaction oldValue: PendingTransaction) -> PendingTransaction {
        var pendingTransaction = oldValue
        let quoteSubscription = pendingTransaction.quoteSubscription
        quoteSubscription?.dispose()
        pendingTransaction.engineState[.quoteSubscription] = nil
        return pendingTransaction.update(confirmations: [])
    }

    func createOrder(pendingTransaction: PendingTransaction) -> Single<SellOrder> {
        currencyConversionService
            .convert(pendingTransaction.amount, to: sourceAsset)
            .asSingle()
            .flatMap(weak: self) { (self, convertedAmount) -> Single<SellOrder> in
                self.orderQuoteRepository.fetchQuote(
                    direction: self.orderDirection,
                    sourceCurrencyType: self.sourceAsset.currencyType,
                    destinationCurrencyType: self.target.currencyType
                )
                .asSingle()
                .flatMap(weak: self) { (self, quote) -> Single<SellOrder> in
                    self.orderCreationRepository.createOrder(
                        direction: self.orderDirection,
                        quoteIdentifier: quote.identifier,
                        volume: convertedAmount,
                        ccy: self.target.currencyType.code
                    )
                    .asSingle()
                }
            }
            .do(onDispose: { [weak self] in
                self?.disposeQuotesFetching(pendingTransaction: pendingTransaction)
            })
    }

    private func disposeQuotesFetching(pendingTransaction: PendingTransaction) {
        pendingTransaction.quoteSubscription?.dispose()
        quotesEngine.stop()
    }
}

extension TransactionLimits {

    func update(with quote: PricedQuote) throws -> TransactionLimits {
        let minimum = try calculateMinimumLimit(for: quote)
        return TransactionLimits(
            currencyType: minimum.currencyType,
            minimum: minimum,
            maximum: maximum,
            maximumDaily: maximumDaily,
            maximumAnnual: maximumAnnual,
            effectiveLimit: effectiveLimit,
            suggestedUpgrade: suggestedUpgrade
        )
    }

    private func calculateMinimumLimit(for quote: PricedQuote) throws -> MoneyValue {
        let destinationCurrency = quote.networkFee.currencyType
        let price = MoneyValue(amount: quote.price, currency: destinationCurrency)
        let totalFees = (try? quote.networkFee + quote.staticFee) ?? MoneyValue.zero(currency: destinationCurrency)
        let convertedFees = totalFees.convert(usingInverse: price, currencyType: currencyType)
        let minimum = minimum ?? .zero(currency: destinationCurrency)
        return (try? minimum + convertedFees) ?? MoneyValue.zero(currency: destinationCurrency)
    }
}

extension PendingTransaction {

    fileprivate var quoteSubscription: Disposable? {
        engineState[.quoteSubscription] as? Disposable
    }
}
