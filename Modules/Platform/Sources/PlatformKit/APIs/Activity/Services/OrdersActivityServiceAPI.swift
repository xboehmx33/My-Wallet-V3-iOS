// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import RxSwift

public protocol OrdersActivityServiceAPI: AnyObject {
    func activity(fiatCurrency: FiatCurrency) -> Single<[CustodialActivityEvent.Fiat]>
    func activity(cryptoCurrency: CryptoCurrency) -> Single<[CustodialActivityEvent.Crypto]>
}
