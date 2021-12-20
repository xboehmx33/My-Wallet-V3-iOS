// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NetworkError

protocol BitPayClientAPI {

    /// 1. First we build the BitPay model
    /// using the `payment-request` endpoint,
    /// passing up an invoice identifier
    /// and a currency type.
    func bitpayPaymentRequest(
        invoiceId: String,
        currency: CryptoCurrency
    ) -> AnyPublisher<BitpayPaymentRequestResponse, NetworkError>

    /// 2. Verify the payment request
    func verifySignedTransaction(
        invoiceId: String,
        currency: CryptoCurrency,
        transactionHex: String,
        transactionSize: Int
    ) -> AnyPublisher<Void, NetworkError>

    /// 3. Post the payment with an `invoiceID`,
    /// the currency, and the transactionHex (not to be confused with the transaction hash)
    func postPayment(
        invoiceId: String,
        currency: CryptoCurrency,
        transactionHex: String,
        transactionSize: Int
    ) -> AnyPublisher<BitPayMemoResponse, NetworkError>
}
