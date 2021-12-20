// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

final class EthereumCryptoAccount: CryptoNonCustodialAccount {

    private(set) lazy var identifier: AnyHashable = "EthereumCryptoAccount.\(publicKey)"
    let label: String
    let asset: CryptoCurrency
    let isDefault: Bool = true

    func createTransactionEngine() -> Any {
        EthereumOnChainTransactionEngineFactory()
    }

    var actionableBalance: Single<MoneyValue> {
        balance
    }

    var balance: Single<MoneyValue> {
        accountDetailsService.accountDetails()
            .map(\.balance)
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
        .just(EthereumReceiveAddress(address: publicKey, label: label, onTxCompleted: onTxCompleted))
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

    private var nonCustodialActivity: Single<[TransactionalActivityItemEvent]> {
        transactionsService
            .transactions
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

    private var isInterestWithdrawAndDepositEnabled: AnyPublisher<Bool, Never> {
        featureFlagsService
            .isEnabled(
                .remote(.interestWithdrawAndDeposit)
            )
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    private let featureFlagsService: FeatureFlagsServiceAPI
    private let publicKey: String
    private let hdAccountIndex: Int
    private let accountDetailsService: EthereumAccountDetailsServiceAPI
    private let priceService: PriceServiceAPI
    private let bridge: EthereumWalletBridgeAPI
    private let transactionsService: EthereumHistoricalTransactionServiceAPI
    private let swapTransactionsService: SwapActivityServiceAPI

    init(
        publicKey: String,
        label: String? = nil,
        hdAccountIndex: Int,
        transactionsService: EthereumHistoricalTransactionServiceAPI = resolve(),
        swapTransactionsService: SwapActivityServiceAPI = resolve(),
        bridge: EthereumWalletBridgeAPI = resolve(),
        accountDetailsService: EthereumAccountDetailsServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        exchangeProviding: ExchangeProviding = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        let asset = CryptoCurrency.coin(.ethereum)
        self.asset = asset
        self.publicKey = publicKey
        self.hdAccountIndex = hdAccountIndex
        self.priceService = priceService
        self.transactionsService = transactionsService
        self.swapTransactionsService = swapTransactionsService
        self.accountDetailsService = accountDetailsService
        self.bridge = bridge
        self.label = label ?? asset.defaultWalletName
        self.featureFlagsService = featureFlagsService
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

    func updateLabel(_ newLabel: String) -> Completable {
        bridge.update(accountIndex: hdAccountIndex, label: newLabel)
    }

    func invalidateAccountBalance() {
        accountDetailsService.invalidateEthereumAccountDetails()
    }
}
