// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
@testable import EthereumKit
import MoneyKit
import NetworkError
import PlatformKit

class TransactionFeeClientAPIMock: TransactionFeeClientAPI {
    var underlyingFees: AnyPublisher<TransactionFeeResponse, NetworkError> = .just(
        .init(
            gasLimit: 10,
            gasLimitContract: 10,
            regular: 10,
            priority: 10
        )
    )

    func fees(
        cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<TransactionFeeResponse, NetworkError> {
        underlyingFees
    }
}
