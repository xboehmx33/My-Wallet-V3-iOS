// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import NetworkError
import PlatformKit
import ToolKit

public protocol BitPayRepositoryAPI {

    func getBitPayPaymentRequest(
        invoiceId: String,
        currency: CryptoCurrency
    ) -> AnyPublisher<BitPayInvoiceTarget, NetworkError>

    func submitBitPayPayment(
        invoiceId: String,
        currency: CryptoCurrency,
        transactionHex: String,
        transactionSize: Int
    ) -> AnyPublisher<BitPayMemo, NetworkError>

    func verifySignedTransaction(
        invoiceId: String,
        currency: CryptoCurrency,
        transactionHex: String,
        transactionSize: Int
    ) -> AnyPublisher<Void, NetworkError>
}
