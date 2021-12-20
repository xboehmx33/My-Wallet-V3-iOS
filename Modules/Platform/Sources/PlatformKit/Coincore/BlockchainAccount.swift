// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import RxSwift
import RxToolKit
import ToolKit

public typealias AvailableActions = Set<AssetAction>

public protocol TradingAccount {}

public protocol BankAccount {}

public protocol NonCustodialAccount {}

public protocol InterestAccount {}

public protocol BlockchainAccount: Account {

    /// A unique identifier for this `BlockchainAccount`.
    ///
    /// This may be used to compare if two BlockchainAccount are the same.
    var identifier: AnyHashable { get }

    /// The total balance on this account.
    var balance: Single<MoneyValue> { get }

    /// The total balance on this account.
    var balancePublisher: AnyPublisher<MoneyValue, Error> { get }

    /// The pending balance of this account.
    var pendingBalance: Single<MoneyValue> { get }

    /// Emits `Set` containing all actions this account can execute.
    var actions: Single<AvailableActions> { get }

    var activity: Single<[ActivityItemEvent]> { get }

    /// Indicates if this account is funded.
    ///
    /// Depending of the account implementation, this may not strictly mean a positive balance.
    /// Some accounts may be set as `isFunded` if they have ever had a positive balance in the past.
    var isFunded: Single<Bool> { get }

    /// The reason why the BlockchainAccount is ineligible for Interest.
    /// This will be `.eligible` if the account is eligible
    var disabledReason: AnyPublisher<InterestAccountIneligibilityReason, Error> { get }

    /// Various `BlockchainAccount` objects fetch their balance in
    /// different ways and use different services. After completing
    /// a transaction we may not want to fetch the balance but do want
    /// fetches anytime after the transaction to reflect the true balance
    /// of the account. All accounts have a 60 second cache but sometimes
    /// this cache should be invalidated.
    func invalidateAccountBalance()

    /// The balance of this account exchanged to the given fiat currency.
    func fiatBalance(fiatCurrency: FiatCurrency) -> AnyPublisher<MoneyValue, Error>

    /// The balance of this account exchanged to the given fiat currency.
    func fiatBalance(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValue, Error>

    /// The balance of this account exchanged to the given fiat currency.
    func balancePair(fiatCurrency: FiatCurrency) -> AnyPublisher<MoneyValuePair, Error>

    /// The balance of this account exchanged to the given fiat currency.
    func balancePair(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValuePair, Error>

    /// Checks if this account can execute the given action.
    func can(perform action: AssetAction) -> Single<Bool>

    /// The `ReceiveAddress` for the given account
    var receiveAddress: Single<ReceiveAddress> { get }

    /// The balance, not including uncleared and locked,
    /// that the user is able to utilize in a transaction
    var actionableBalance: Single<MoneyValue> { get }

    /// Some wallets are double encrypted and have a second password.
    var requireSecondPassword: Single<Bool> { get }
}

extension BlockchainAccount {

    public var balancePublisher: AnyPublisher<MoneyValue, Error> {
        balance.asPublisher()
            .eraseToAnyPublisher()
    }

    public func can(perform action: AssetAction) -> AnyPublisher<Bool, Error> {
        let single: Single<Bool> = can(perform: action)
        return single.asPublisher()
            .eraseToAnyPublisher()
    }
}

extension BlockchainAccount {

    public var disabledReason: AnyPublisher<InterestAccountIneligibilityReason, Error> {
        .just(.eligible)
    }

    public func balancePair(fiatCurrency: FiatCurrency) -> AnyPublisher<MoneyValuePair, Error> {
        balancePair(fiatCurrency: fiatCurrency, at: .now)
    }

    public func fiatBalance(fiatCurrency: FiatCurrency) -> AnyPublisher<MoneyValue, Error> {
        fiatBalance(fiatCurrency: fiatCurrency, at: .now)
    }

    public func fiatBalance(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValue, Error> {
        balancePair(fiatCurrency: fiatCurrency, at: time)
            .map(\.quote)
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == [SingleAccount] {

    /// Maps each `[SingleAccount]` object filtering out accounts that match the given `BlockchainAccount` identifier.
    public func mapFilter(excluding identifier: AnyHashable) -> AnyPublisher<Output, Failure> {
        map { accounts in
            accounts.filter { $0.identifier != identifier }
        }
        .eraseToAnyPublisher()
    }
}
