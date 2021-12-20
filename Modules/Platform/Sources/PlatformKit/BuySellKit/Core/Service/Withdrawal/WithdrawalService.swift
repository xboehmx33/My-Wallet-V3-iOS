// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import RxSwift

public protocol WithdrawalServiceAPI {

    func withdrawFeeAndLimit(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<WithdrawalFeeAndLimit>

    func withdrawal(
        for checkout: WithdrawalCheckoutData
    ) -> Single<Result<FiatValue, Error>>

    func withdrawalFee(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<FiatValue>

    func withdrawalMinAmount(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<FiatValue>
}
