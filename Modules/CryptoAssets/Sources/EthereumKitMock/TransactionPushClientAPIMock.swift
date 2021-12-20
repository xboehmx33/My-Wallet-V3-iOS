// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
@testable import EthereumKit
import NetworkError
import PlatformKit

class TransactionPushClientAPIMock: TransactionPushClientAPI {

    var lastPushedTransaction: EthereumTransactionEncoded?
    var pushTransactionValue: AnyPublisher<EthereumPushTxResponse, NetworkError> =
        .just(EthereumPushTxResponse(txHash: "txHash"))

    func push(
        transaction: EthereumTransactionEncoded
    ) -> AnyPublisher<EthereumPushTxResponse, NetworkError> {
        lastPushedTransaction = transaction
        return pushTransactionValue
    }
}
