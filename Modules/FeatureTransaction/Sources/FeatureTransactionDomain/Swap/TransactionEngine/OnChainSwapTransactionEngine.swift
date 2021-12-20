// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

final class OnChainSwapTransactionEngine: SwapTransactionEngine {

    let walletCurrencyService: FiatCurrencyServiceAPI
    let currencyConversionService: CurrencyConversionServiceAPI

    let receiveAddressFactory: ExternalAssetAddressServiceAPI
    let onChainEngine: OnChainTransactionEngine
    let orderCreationRepository: OrderCreationRepositoryAPI
    var orderDirection: OrderDirection {
        target is TradingAccount ? .fromUserKey : .onChain
    }

    let orderQuoteRepository: OrderQuoteRepositoryAPI
    let orderUpdateRepository: OrderUpdateRepositoryAPI
    let quotesEngine: SwapQuotesEngine
    let requireSecondPassword: Bool
    let transactionLimitsService: TransactionLimitsServiceAPI
    var askForRefreshConfirmation: ((Bool) -> Completable)!
    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!

    init(
        quotesEngine: SwapQuotesEngine,
        requireSecondPassword: Bool,
        onChainEngine: OnChainTransactionEngine,
        orderQuoteRepository: OrderQuoteRepositoryAPI = resolve(),
        orderCreationRepository: OrderCreationRepositoryAPI = resolve(),
        orderUpdateRepository: OrderUpdateRepositoryAPI = resolve(),
        transactionLimitsService: TransactionLimitsServiceAPI = resolve(),
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        receiveAddressFactory: ExternalAssetAddressServiceAPI = resolve()
    ) {
        self.quotesEngine = quotesEngine
        self.requireSecondPassword = requireSecondPassword
        self.orderQuoteRepository = orderQuoteRepository
        self.orderCreationRepository = orderCreationRepository
        self.orderUpdateRepository = orderUpdateRepository
        self.transactionLimitsService = transactionLimitsService
        self.walletCurrencyService = walletCurrencyService
        self.currencyConversionService = currencyConversionService
        self.onChainEngine = onChainEngine
        self.receiveAddressFactory = receiveAddressFactory
    }

    func assertInputsValid() {
        // We don't assert anything for On Chain Swap.
    }

    private func startOnChainEngine(pricedQuote: PricedQuote) -> Completable {
        let value = receiveAddressFactory.makeExternalAssetAddress(
            asset: sourceAsset,
            address: pricedQuote.sampleDepositAddress,
            label: pricedQuote.sampleDepositAddress,
            onTxCompleted: { _ in .empty() }
        )
        switch value {
        case .failure(let error):
            return .just(event: .error(error))
        case .success(let receiveAddress):
            onChainEngine.start(
                sourceAccount: sourceAccount,
                transactionTarget: receiveAddress,
                askForRefreshConfirmation: { _ in .empty() }
            )
            return .just(event: .completed)
        }
    }

    private func startOnChainEngine(with transactionTarget: CryptoReceiveAddress) {
        onChainEngine.start(
            sourceAccount: sourceAccount,
            transactionTarget: transactionTarget,
            askForRefreshConfirmation: { _ in .empty() }
        )
    }

    private func defaultFeeLevel(pendingTransaction: PendingTransaction) -> FeeLevel {
        if pendingTransaction.feeSelection.availableLevels.contains(.priority) {
            return .priority
        }
        return pendingTransaction.feeSelection.selectedLevel
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        quotesEngine
            .getRate(direction: orderDirection, pair: pair)
            .take(1)
            .asSingle()
            .flatMap(weak: self) { (self, pricedQuote) -> Single<PendingTransaction> in
                self.startOnChainEngine(pricedQuote: pricedQuote)
                    .andThen(
                        Single.zip(
                            self.walletCurrencyService.displayCurrency.asSingle(),
                            self.onChainEngine.initializeTransaction()
                        )
                    )
                    .flatMap(weak: self) { (self, payload) -> Single<PendingTransaction> in
                        let (fiatCurrency, pendingTransaction) = payload

                        let fallback = PendingTransaction(
                            amount: .zero(currency: self.sourceAsset),
                            available: .zero(currency: self.targetAsset),
                            feeAmount: .zero(currency: self.targetAsset),
                            feeForFullAvailable: .zero(currency: self.sourceAsset),
                            feeSelection: .empty(asset: self.sourceAsset),
                            selectedFiatCurrency: fiatCurrency
                        )
                        return self.updateLimits(
                            pendingTransaction: pendingTransaction,
                            pricedQuote: pricedQuote
                        )
                        .map(weak: self) { (self, pendingTx) -> PendingTransaction in
                            pendingTx
                                .update(selectedFeeLevel: self.defaultFeeLevel(pendingTransaction: pendingTx))
                        }
                        .handlePendingOrdersError(initialValue: fallback)
                    }
            }
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        onChainEngine
            .doValidateAll(pendingTransaction: pendingTransaction)
            .flatMap(weak: self) { (self, pendingTransaction) -> Single<PendingTransaction> in
                switch pendingTransaction.validationState {
                case .canExecute:
                    return self.defaultDoValidateAll(pendingTransaction: pendingTransaction)
                default:
                    return .just(pendingTransaction)
                }
            }
            .updateTxValiditySingle(pendingTransaction: pendingTransaction)
    }

    func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult> {
        createOrder(pendingTransaction: pendingTransaction)
            .flatMap(weak: self) { (self, swapOrder) -> Single<TransactionResult> in
                guard let depositAddress = swapOrder.depositAddress else {
                    throw PlatformKitError.illegalStateException(message: "Missing deposit address")
                }
                return self.receiveAddressFactory
                    .makeExternalAssetAddress(
                        asset: self.sourceAsset,
                        address: depositAddress,
                        label: depositAddress,
                        onTxCompleted: { _ in .empty() }
                    )
                    .single
                    .flatMap(weak: self) { (self, transactionTarget) -> Single<PendingTransaction> in
                        self.onChainEngine
                            .restart(transactionTarget: transactionTarget, pendingTransaction: pendingTransaction)
                    }
                    .flatMap(weak: self) { (self, pendingTransaction) -> Single<TransactionResult> in
                        self.onChainEngine
                            .execute(pendingTransaction: pendingTransaction, secondPassword: secondPassword)
                            .catchError(weak: self) { (self, error) -> Single<TransactionResult> in
                                self.orderUpdateRepository
                                    .updateOrder(identifier: swapOrder.identifier, success: false)
                                    .asObservable()
                                    .ignoreElements()
                                    .asCompletable()
                                    .catchError { _ in .empty() }
                                    .andThen(.error(error))
                            }
                            .flatMap(weak: self) { (self, result) -> Single<TransactionResult> in
                                self.orderUpdateRepository
                                    .updateOrder(identifier: swapOrder.identifier, success: true)
                                    .asObservable()
                                    .ignoreElements()
                                    .asCompletable()
                                    .catchError { _ in .empty() }
                                    .andThen(.just(result))
                            }
                    }
            }
    }

    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction> {
        onChainEngine.doUpdateFeeLevel(
            pendingTransaction: pendingTransaction,
            level: level,
            customFeeAmount: customFeeAmount
        )
    }

    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateUpdateAmount(amount)
            .flatMap(weak: self) { (self, amount) -> Single<PendingTransaction> in
                self.onChainEngine
                    .update(amount: amount, pendingTransaction: pendingTransaction)
                    .do(onSuccess: { pendingTransaction in
                        self.quotesEngine.updateAmount(pendingTransaction.amount.amount)
                    })
                    .map(weak: self) { (self, pendingTransaction) -> PendingTransaction in
                        self.clearConfirmations(pendingTransaction: pendingTransaction)
                    }
            }
    }
}
