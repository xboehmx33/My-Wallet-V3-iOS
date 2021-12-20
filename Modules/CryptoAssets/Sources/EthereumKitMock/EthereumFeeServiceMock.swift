// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import EthereumKit
import MoneyKit
import PlatformKit
import RxSwift

class EthereumFeeServiceMock: EthereumFeeServiceAPI {
    var underlyingFees: EthereumTransactionFee

    func fees(cryptoCurrency: CryptoCurrency) -> Single<EthereumTransactionFee> {
        .just(underlyingFees)
    }

    init(underlyingFees: EthereumTransactionFee) {
        self.underlyingFees = underlyingFees
    }
}
