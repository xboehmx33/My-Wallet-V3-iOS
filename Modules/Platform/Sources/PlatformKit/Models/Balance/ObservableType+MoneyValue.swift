// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import RxSwift

extension Observable where Element == CryptoValue {
    public var moneyValue: Observable<MoneyValue> {
        map(\.moneyValue)
    }
}

extension Observable where Element == FiatValue {
    public var moneyValue: Observable<MoneyValue> {
        map(\.moneyValue)
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == CryptoValue {
    public var moneyValue: Single<MoneyValue> {
        map(\.moneyValue)
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == FiatValue {
    public var moneyValue: Single<MoneyValue> {
        map(\.moneyValue)
    }
}
