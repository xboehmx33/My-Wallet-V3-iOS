// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

public protocol WithdrawalClientAPI: AnyObject {
    /// Requests the withdraw fee for the requested currency
    ///
    /// - parameter currency: A `FiatCurrency` value, for the request
    /// - Returns: A `Single<MoneyValue>` object with the fetched fee value
    func withdrawFee(
        currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> AnyPublisher<WithdrawFeesResponse, NabuNetworkError>

    /// Requests the withdrawal for the requested checkout data
    ///
    /// - Parameter data: A `WithdrawalCheckoutData` object reprenting the details of the withdrawal
    /// - Returns: A `Single<WithdrawalCheckoutResponse>` object with the fetched response
    func withdraw(
        data: WithdrawalCheckoutData
    ) -> AnyPublisher<WithdrawalCheckoutResponse, NabuNetworkError>
}
