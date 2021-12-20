// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import RxSwift

public protocol FiatAccount: SingleAccount {
    var fiatCurrency: FiatCurrency { get }
    var canWithdrawFunds: Single<Bool> { get }
}

extension FiatAccount {

    public var currencyType: CurrencyType {
        fiatCurrency.currencyType
    }

    public var pendingBalance: Single<MoneyValue> {
        balance
    }

    public var actionableBalance: Single<MoneyValue> {
        balance
    }

    public func balancePair(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValuePair, Error> {
        .just(
            .zero(
                baseCurrency: fiatCurrency.currencyType,
                quoteCurrency: fiatCurrency.currencyType
            )
        )
    }

    public var receiveAddress: Single<ReceiveAddress> {
        .error(ReceiveAddressError.notSupported)
    }

    public var requireSecondPassword: Single<Bool> {
        .just(false)
    }
}
