// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Localization
import MoneyKit
import RxSwift
import ToolKit

final class FiatCustodialAccount: FiatAccount {

    private(set) lazy var identifier: AnyHashable = "FiatCustodialAccount.\(fiatCurrency.code)"
    let isDefault: Bool = true
    let label: String
    let fiatCurrency: FiatCurrency

    var receiveAddress: Single<ReceiveAddress> {
        .error(ReceiveAddressError.notSupported)
    }

    var disabledReason: AnyPublisher<InterestAccountIneligibilityReason, Error> {
        interestEligibilityRepository
            .fetchInterestAccountEligibilityForCurrencyCode(currencyType.code)
            .map(\.ineligibilityReason)
            .eraseError()
    }

    var activity: Single<[ActivityItemEvent]> {
        activityFetcher
            .activity(fiatCurrency: fiatCurrency)
            .map { items in
                items.map(ActivityItemEvent.fiat)
            }
    }

    var actions: Single<AvailableActions> {
        let hasActionableBalance = actionableBalance
            .map(\.isPositive)
            .catchErrorJustReturn(false)
        let canTransactWithBanks = paymentMethodService
            .canTransactWithBankPaymentMethods(fiatCurrency: fiatCurrency)
            .catchErrorJustReturn(false)

        return Single.zip(canTransactWithBanks, hasActionableBalance)
            .map { fiatSupported, hasPositiveBalance in
                var availableActions: AvailableActions = [.viewActivity]
                if fiatSupported {
                    availableActions.insert(.deposit)
                    if hasPositiveBalance {
                        // TICKET: IOS-4988 - Implement canWithdrawFunds in FiatCustodialAccount
                        availableActions.insert(.withdraw)
                    }
                }
                return availableActions
            }
    }

    var canWithdrawFunds: Single<Bool> {
        // TODO: Fetch transaction history and filer
        // for transactions that are `withdrawals` and have a
        // transactionState of `.pending`.
        // If there are no items, the user can withdraw funds.
        unimplemented()
    }

    var pendingBalance: Single<MoneyValue> {
        balances
            .map(\.balance?.pending)
            .replaceNil(with: .zero(currency: currencyType))
            .asSingle()
    }

    var balance: Single<MoneyValue> {
        balancePublisher
            .asSingle()
    }

    var balancePublisher: AnyPublisher<MoneyValue, Error> {
        balances
            .map(\.balance?.available)
            .replaceNil(with: .zero(currency: currencyType))
            .mapError()
    }

    var actionableBalance: Single<MoneyValue> {
        balance
    }

    var isFunded: Single<Bool> {
        balance.map(\.isPositive)
    }

    private let interestEligibilityRepository: InterestAccountEligibilityRepositoryAPI
    private let activityFetcher: OrdersActivityServiceAPI
    private let balanceService: TradingBalanceServiceAPI
    private let priceService: PriceServiceAPI
    private let paymentMethodService: PaymentMethodTypesServiceAPI
    private var balances: AnyPublisher<CustodialAccountBalanceState, Never> {
        balanceService.balance(for: currencyType)
    }

    init(
        fiatCurrency: FiatCurrency,
        interestEligibilityRepository: InterestAccountEligibilityRepositoryAPI = resolve(),
        activityFetcher: OrdersActivityServiceAPI = resolve(),
        balanceService: TradingBalanceServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        paymentMethodService: PaymentMethodTypesServiceAPI = resolve()
    ) {
        label = fiatCurrency.defaultWalletName
        self.interestEligibilityRepository = interestEligibilityRepository
        self.fiatCurrency = fiatCurrency
        self.activityFetcher = activityFetcher
        self.paymentMethodService = paymentMethodService
        self.balanceService = balanceService
        self.priceService = priceService
    }

    func can(perform action: AssetAction) -> Single<Bool> {
        switch action {
        case .viewActivity:
            return .just(true)
        case .buy,
             .send,
             .sell,
             .swap,
             .sign,
             .receive,
             .interestTransfer,
             .interestWithdraw:
            return .just(false)
        case .deposit:
            return paymentMethodService
                .canTransactWithBankPaymentMethods(fiatCurrency: fiatCurrency)
        case .withdraw:
            // TODO: Account for OB
            let hasActionableBalance = actionableBalance
                .map(\.isPositive)
            let canTransactWithBanks = paymentMethodService
                .canTransactWithBankPaymentMethods(fiatCurrency: fiatCurrency)
            return Single.zip(canTransactWithBanks, hasActionableBalance)
                .map { canTransact, hasBalance in
                    canTransact && hasBalance
                }
        }
    }

    func balancePair(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValuePair, Error> {
        priceService
            .price(of: self.fiatCurrency, in: fiatCurrency, at: time)
            .eraseError()
            .zip(balancePublisher)
            .tryMap { fiatPrice, balance in
                MoneyValuePair(base: balance, exchangeRate: fiatPrice.moneyValue)
            }
            .eraseToAnyPublisher()
    }

    func invalidateAccountBalance() {
        balanceService
            .invalidateTradingAccountBalances()
    }
}
