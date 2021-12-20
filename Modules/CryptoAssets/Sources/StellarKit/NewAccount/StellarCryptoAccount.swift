// Copyright © Blockchain Luxembourg S.A. All rights reserved.
// swiftformat:disable redundantSelf

import Combine
import DIKit
import MoneyKit
import PlatformKit
import RxSwift
import RxToolKit
import ToolKit

final class StellarCryptoAccount: CryptoNonCustodialAccount {

    private(set) lazy var identifier: AnyHashable = "StellarCryptoAccount.\(publicKey)"
    let label: String
    let asset: CryptoCurrency
    let isDefault: Bool = true

    func createTransactionEngine() -> Any {
        StellarOnChainTransactionEngineFactory()
    }

    var balance: Single<MoneyValue> {
        accountCache.valueSingle
            .map(\.balance)
            .moneyValue
    }

    var actionableBalance: Single<MoneyValue> {
        accountCache.valueSingle
            .map(\.actionableBalance)
            .moneyValue
    }

    var pendingBalance: Single<MoneyValue> {
        .just(.zero(currency: asset))
    }

    var actions: Single<AvailableActions> {
        Single.zip(
            isFunded,
            isInterestTransferAvailable.asSingle()
        )
        .map { isFunded, isInterestEnabled -> AvailableActions in
            var base: AvailableActions = [.viewActivity, .receive, .send, .buy]
            if isFunded {
                base.insert(.swap)
                base.insert(.sell)
                if isInterestEnabled {
                    base.insert(.interestTransfer)
                }
            }
            return base
        }
    }

    var receiveAddress: Single<ReceiveAddress> {
        .just(StellarReceiveAddress(address: publicKey, label: label))
    }

    var activity: Single<[ActivityItemEvent]> {
        Single.zip(nonCustodialActivity, swapActivity)
            .map { nonCustodialActivity, swapActivity in
                Self.reconcile(swapEvents: swapActivity, noncustodial: nonCustodialActivity)
            }
    }

    private var isInterestTransferAvailable: AnyPublisher<Bool, Never> {
        Single.zip(
            canPerformInterestTransfer(),
            isInterestWithdrawAndDepositEnabled
                .asSingle()
        )
        .map { $0.0 && $0.1 }
        .asPublisher()
        .replaceError(with: false)
        .eraseToAnyPublisher()
    }

    private var isInterestWithdrawAndDepositEnabled: AnyPublisher<Bool, Never> {
        featureFlagsService
            .isEnabled(
                .remote(.interestWithdrawAndDeposit)
            )
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    private var nonCustodialActivity: Single<[TransactionalActivityItemEvent]> {
        operationsService
            .transactions(accountID: publicKey, size: 50)
            .map { response in
                response
                    .map(\.activityItemEvent)
            }
            .catchErrorJustReturn([])
    }

    private var swapActivity: Single<[SwapActivityItemEvent]> {
        swapTransactionsService
            .fetchActivity(cryptoCurrency: asset, directions: custodialDirections)
            .catchErrorJustReturn([])
    }

    private let featureFlagsService: FeatureFlagsServiceAPI
    private let publicKey: String
    private let hdAccountIndex: Int
    private let bridge: StellarWalletBridgeAPI
    private let accountDetailsService: StellarAccountDetailsServiceAPI
    private let priceService: PriceServiceAPI
    private let accountCache: CachedValue<StellarAccountDetails>
    private let operationsService: StellarHistoricalTransactionServiceAPI
    private let swapTransactionsService: SwapActivityServiceAPI

    init(
        publicKey: String,
        label: String? = nil,
        hdAccountIndex: Int,
        bridge: StellarWalletBridgeAPI = resolve(),
        operationsService: StellarHistoricalTransactionServiceAPI = resolve(),
        swapTransactionsService: SwapActivityServiceAPI = resolve(),
        accountDetailsService: StellarAccountDetailsServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        let asset = CryptoCurrency.coin(.stellar)
        self.asset = asset
        self.bridge = bridge
        self.publicKey = publicKey
        self.hdAccountIndex = hdAccountIndex
        self.label = label ?? asset.defaultWalletName
        self.accountDetailsService = accountDetailsService
        self.swapTransactionsService = swapTransactionsService
        self.operationsService = operationsService
        self.priceService = priceService
        self.featureFlagsService = featureFlagsService
        accountCache = CachedValue(
            configuration: .periodic(
                seconds: 20,
                schedulerIdentifier: "StellarCryptoAccount"
            )
        )
        accountCache.setFetch(weak: self) { (self) -> Single<StellarAccountDetails> in
            self.accountDetailsService.accountDetails(for: publicKey)
        }
    }

    func can(perform action: AssetAction) -> Single<Bool> {
        switch action {
        case .receive,
             .send,
             .viewActivity,
             .buy:
            return .just(true)
        case .interestTransfer:
            return isInterestTransferAvailable
                .asSingle()
                .flatMap { [isFunded] isEnabled in
                    isEnabled ? isFunded : .just(false)
                }
        case .deposit,
             .sign,
             .withdraw,
             .interestWithdraw:
            return .just(false)
        case .sell:
            return isFunded
        case .swap:
            return isFunded
        }
    }

    func updateLabel(_ newLabel: String) -> Completable {
        bridge.update(accountIndex: hdAccountIndex, label: newLabel)
    }

    func balancePair(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValuePair, Error> {
        priceService
            .price(of: asset, in: fiatCurrency, at: time)
            .eraseError()
            .zip(balancePublisher)
            .tryMap { fiatPrice, balance in
                MoneyValuePair(base: balance, exchangeRate: fiatPrice.moneyValue)
            }
            .eraseToAnyPublisher()
    }

    func invalidateAccountBalance() {
        accountCache
            .invalidate()
    }
}
