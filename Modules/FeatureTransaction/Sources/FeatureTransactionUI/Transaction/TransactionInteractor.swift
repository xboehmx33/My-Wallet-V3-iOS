// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Combine
import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import RIBs
import RxSwift
import ToolKit

final class TransactionInteractor {

    private enum Error: LocalizedError {
        case loadingFailed(account: BlockchainAccount, action: AssetAction, error: String)

        var errorDescription: String? {
            switch self {
            case .loadingFailed(let account, let action, let error):
                let type = String(reflecting: account)
                let asset = account.currencyType.code
                let label = account.label
                return "Failed to load: '\(type)' asset '\(asset)' label '\(label)' action '\(action)' error '\(error)'."
            }
        }
    }

    private let coincore: CoincoreAPI
    private let availablePairsService: AvailableTradingPairsServiceAPI
    private let swapEligibilityService: EligibilityServiceAPI
    private let paymentMethodsService: PaymentAccountsServiceAPI
    private let linkedBanksFactory: LinkedBanksFactoryAPI
    private let userTiersService: KYCTiersServiceAPI
    private let ordersService: OrdersServiceAPI
    private let errorRecorder: ErrorRecording
    private var cancellables: Set<AnyCancellable> = []
    private var transactionProcessor: TransactionProcessor?

    /// Used to invalidate the transaction processor chain.
    private let invalidate = PublishSubject<Void>()

    init(
        coincore: CoincoreAPI = resolve(),
        availablePairsService: AvailableTradingPairsServiceAPI = resolve(),
        swapEligibilityService: EligibilityServiceAPI = resolve(),
        paymentMethodsService: PaymentAccountsServiceAPI = resolve(),
        linkedBanksFactory: LinkedBanksFactoryAPI = resolve(),
        userTiersService: KYCTiersServiceAPI = resolve(),
        ordersService: OrdersServiceAPI = resolve(),
        errorRecorder: ErrorRecording = resolve()
    ) {
        self.coincore = coincore
        self.errorRecorder = errorRecorder
        self.availablePairsService = availablePairsService
        self.swapEligibilityService = swapEligibilityService
        self.paymentMethodsService = paymentMethodsService
        self.linkedBanksFactory = linkedBanksFactory
        self.userTiersService = userTiersService
        self.ordersService = ordersService
    }

    func initializeTransaction(
        sourceAccount: BlockchainAccount,
        transactionTarget: TransactionTarget,
        action: AssetAction
    ) -> Observable<PendingTransaction> {
        coincore
            .createTransactionProcessor(
                with: sourceAccount,
                target: transactionTarget,
                action: action
            )
            .do(onSuccess: { [weak self] transactionProcessor in
                guard let self = self else { return }
                self.transactionProcessor = transactionProcessor
            })
            .asObservable()
            .flatMap(\.initializeTransaction)
            .takeUntil(invalidate)
    }

    deinit {
        reset()
        transactionProcessor = nil
    }

    func invalidateTransaction() -> Completable {
        Completable.create(weak: self) { (self, complete) -> Disposable in
            self.reset()
            self.transactionProcessor = nil
            complete(.completed)
            return Disposables.create()
        }
    }

    func update(amount: MoneyValue) -> Completable {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.updateAmount(amount: amount)
    }

    func updateTransactionFees(with level: FeeLevel, amount: MoneyValue?) -> Completable {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.updateFeeLevel(level, customFeeAmount: amount)
    }

    func fetchPaymentAccounts(for currency: CryptoCurrency, amount: MoneyValue?) -> Single<[SingleAccount]> {
        let amount = amount ?? .zero(currency: currency)
        return paymentMethodsService
            .fetchPaymentMethodAccounts(for: currency, amount: amount)
            .map { $0 }
            .asSingle()
    }

    func getAvailableSourceAccounts(
        action: AssetAction,
        transactionTarget: TransactionTarget?
    ) -> Single<[SingleAccount]> {
        let allEligibleCryptoAccounts: Single<[CryptoAccount]> = coincore
            .allAccounts
            .eraseError()
            .map(\.accounts)
            .flatMapFilter(
                action: action,
                failSequence: false,
                onError: { [errorRecorder] account, error in
                    let error: Error = .loadingFailed(
                        account: account,
                        action: action,
                        error: String(describing: error)
                    )
                    errorRecorder.error(error)
                }
            )
            .map { accounts in
                accounts.compactMap { account in
                    account as? CryptoAccount
                }
            }
            .asSingle()
        switch action {
        case .interestTransfer:
            guard let account = transactionTarget as? BlockchainAccount else {
                impossible("A target account is required for this.")
            }
            return coincore
                .cryptoAccounts(supporting: .interestTransfer)
                .asSingle()
                .map { $0.filter { $0.currencyType == account.currencyType } }

        case .buy:
            // TODO: the new limits API will require an amount
            return fetchPaymentAccounts(for: .coin(.bitcoin), amount: nil)
        case .swap:
            let tradingPairs = availablePairsService.availableTradingPairs
            return Single.zip(allEligibleCryptoAccounts, tradingPairs)
                .map { (allAccounts: [CryptoAccount], tradingPairs: [OrderPair]) -> [CryptoAccount] in
                    allAccounts.filter { account -> Bool in
                        account.isAvailableToSwapFrom(tradingPairs: tradingPairs)
                    }
                }
        case .sell:
            return allEligibleCryptoAccounts.map { $0 as [SingleAccount] }
        case .deposit, .withdraw:
            return linkedBanksFactory.linkedBanks.map { $0.map { $0 as SingleAccount } }
        default:
            preconditionFailure("Source account should be preselected for action \(action)")
        }
    }

    func getTargetAccounts(sourceAccount: BlockchainAccount, action: AssetAction) -> Single<[SingleAccount]> {
        switch action {
        case .swap:
            guard let cryptoAccount = sourceAccount as? CryptoAccount else {
                fatalError("Expected a CryptoAccount.")
            }
            return swapTargets(sourceAccount: cryptoAccount)
        case .interestTransfer:
            guard let cryptoAccount = sourceAccount as? CryptoAccount else {
                fatalError("Expected a CryptoAccount.")
            }
            return interestDepositTargets(sourceAccount: cryptoAccount)
        case .interestWithdraw:
            guard let cryptoAccount = sourceAccount as? CryptoAccount else {
                fatalError("Expected a CryptoAccount.")
            }
            return interestWithdrawTargets(sourceAccount: cryptoAccount)
        case .send:
            guard let cryptoAccount = sourceAccount as? CryptoAccount else {
                fatalError("Expected a CryptoAccount.")
            }
            return sendTargets(sourceAccount: cryptoAccount)
        case .deposit:
            return linkedBanksFactory.nonWireTransferBanks.map { $0.map { $0 as SingleAccount } }
        case .withdraw:
            return linkedBanksFactory.linkedBanks.map { $0.map { $0 as SingleAccount } }
        case .buy:
            return coincore
                .cryptoAccounts(supporting: .buy, filter: .custodial)
                .asSingle()
                .map { $0 }
        case .sell:
            return coincore.allAccounts
                .map(\.accounts)
                .map {
                    $0.compactMap { account in
                        account as? FiatAccount
                    }
                }
                .asObservable()
                .asSingle()
        case .sign,
             .receive,
             .viewActivity:
            unimplemented()
        }
    }

    func verifyAndExecute(order: TransactionOrder?, secondPassword: String) -> Single<TransactionResult> {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.execute(
            order: order,
            secondPassword: secondPassword
        )
    }

    func createOrder() -> Single<TransactionOrder?> {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.createOrder()
    }

    func cancelOrder(with identifier: String) -> Single<Void> {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.cancelOrder(with: identifier)
    }

    func modifyTransactionConfirmation(_ newConfirmation: TransactionConfirmation) -> Completable {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.set(transactionConfirmation: newConfirmation)
    }

    func reset() {
        invalidate.on(.next(()))
        transactionProcessor?.reset()
    }

    var startCryptoRatePairFetch: Observable<MoneyValuePair> {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.transactionExchangeRatePair
    }

    var startFiatRatePairsFetch: Observable<TransactionMoneyValuePairs> {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.fiatExchangeRatePairs
    }

    var canTransactFiat: Bool {
        transactionProcessor?.canTransactFiat ?? false
    }

    var validateTransaction: Completable {
        guard let transactionProcessor = transactionProcessor else {
            fatalError("Tx Processor is nil")
        }
        return transactionProcessor.validateAll()
    }

    func fetchUserKYCStatus() -> AnyPublisher<TransactionState.KYCStatus?, Never> {
        userTiersService.fetchTiers()
            .zip(
                userTiersService.checkSimplifiedDueDiligenceVerification(pollUntilComplete: false)
                    .setFailureType(to: KYCTierServiceError.self)
            )
            .map { userTiers, isSDDVerified -> TransactionState.KYCStatus? in
                TransactionState.KYCStatus(tiers: userTiers, isSDDVerified: isSDDVerified)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    func pollOrderStatusUntilDoneOrTimeout(orderId: String) -> AnyPublisher<OrderDetails.State, Never> {
        ordersService
            .fetchOrder(with: orderId)
            .asPublisher()
            .startPolling(
                timeoutInterval: .seconds(30),
                until: { $0.isFinal }
            )
            .map(\.state)
            .replaceError(with: .pendingConfirmation)
            .eraseToAnyPublisher()
    }

    // MARK: - Private Functions

    private func interestWithdrawTargets(sourceAccount: CryptoAccount) -> Single<[SingleAccount]> {
        coincore
            .getTransactionTargets(
                sourceAccount: sourceAccount,
                action: .interestWithdraw
            )
            .asSingle()
    }

    private func interestDepositTargets(sourceAccount: CryptoAccount) -> Single<[SingleAccount]> {
        coincore
            .getTransactionTargets(
                sourceAccount: sourceAccount,
                action: .interestTransfer
            )
            .asSingle()
    }

    private func sendTargets(sourceAccount: CryptoAccount) -> Single<[SingleAccount]> {
        coincore
            .getTransactionTargets(
                sourceAccount: sourceAccount,
                action: .send
            )
            .asObservable()
            .asSingle()
    }

    private func swapTargets(sourceAccount: CryptoAccount) -> Single<[SingleAccount]> {
        let transactionTargets = coincore
            .getTransactionTargets(
                sourceAccount: sourceAccount,
                action: .swap
            )
            .asObservable()
            .asSingle()
        let tradingPairs = availablePairsService.availableTradingPairs
        let isEligible = swapEligibilityService.isEligible
        return Single.zip(transactionTargets, tradingPairs, isEligible)
            .map { (accounts: [SingleAccount], pairs: [OrderPair], isEligible: Bool) -> [SingleAccount] in
                accounts
                    .filter { $0 is CryptoAccount }
                    .filter { pairs.contains(source: sourceAccount.currencyType, destination: $0.currencyType) }
                    .filter { isEligible || $0 is NonCustodialAccount }
            }
    }
}

extension Array where Element == OrderPair {
    fileprivate func contains(source: CurrencyType, destination: CurrencyType) -> Bool {
        contains(where: { $0.sourceCurrencyType == source && $0.destinationCurrencyType == destination })
    }
}

extension CryptoAccount {
    fileprivate func isAvailableToSwapFrom(tradingPairs: [OrderPair]) -> Bool {
        tradingPairs.contains { pair in
            pair.sourceCurrencyType == asset
        }
    }
}
