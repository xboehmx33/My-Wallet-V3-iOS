// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

final class EnterAmountCryptoCurrencyProvider: CryptoCurrencyServiceAPI {

    private let transactionModel: TransactionModel

    var cryptoCurrencyObservable: Observable<CryptoCurrency> {
        transactionModel
            .state
            .distinctUntilChanged()
            .compactMap { transactionState -> CryptoCurrency? in
                switch transactionState.action {
                case .buy:
                    return transactionState
                        .destination?
                        .currencyType
                        .cryptoCurrency
                default:
                    unimplemented()
                }
            }
            .subscribeOn(MainScheduler.asyncInstance)
    }

    var cryptoCurrency: Single<CryptoCurrency> {
        cryptoCurrencyObservable
            .take(1)
            .asSingle()
    }

    init(transactionModel: TransactionModel) {
        self.transactionModel = transactionModel
    }
}
