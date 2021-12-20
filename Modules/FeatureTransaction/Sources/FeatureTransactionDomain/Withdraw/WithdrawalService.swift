// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit
import RxSwift

final class WithdrawalService: WithdrawalServiceAPI {

    private let client: WithdrawalClientAPI
    private let transactionLimitsService: TransactionLimitsServiceAPI

    init(
        client: WithdrawalClientAPI,
        transactionLimitsService: TransactionLimitsServiceAPI
    ) {
        self.client = client
        self.transactionLimitsService = transactionLimitsService
    }

    func withdrawFeeAndLimit(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<WithdrawalFeeAndLimit> {
        client.withdrawFee(currency: currency, paymentMethodType: paymentMethodType)
            .map { response -> (CurrencyFeeResponse, CurrencyFeeResponse) in
                guard let fees = response.fees.first(where: { $0.symbol == currency.code }) else {
                    fatalError("Expected fees for currency: \(currency)")
                }
                guard let mins = response.minAmounts.first(where: { $0.symbol == currency.code }) else {
                    fatalError("Expected minimum values for currency: \(currency)")
                }
                return (fees, mins)
            }
            .mapError(TransactionLimitsServiceError.network)
            .zip(
                transactionLimitsService.fetchLimits(
                    source: LimitsAccount(
                        currency: currency.currencyType,
                        accountType: .custodial
                    ),
                    destination: LimitsAccount(
                        currency: currency.currencyType,
                        accountType: .nonCustodial
                    ),
                    limitsCurrency: currency
                )
            )
            .map { withdrawData, limitsData -> WithdrawalFeeAndLimit in
                let (feeResponse, minResponse) = withdrawData
                let zero: FiatValue = .zero(currency: currency)
                return WithdrawalFeeAndLimit(
                    maxLimit: limitsData.maximum?.fiatValue,
                    minLimit: FiatValue.create(minor: minResponse.minorValue, currency: currency) ?? zero,
                    fee: FiatValue.create(minor: feeResponse.minorValue, currency: currency) ?? zero
                )
            }
            .asSingle()
    }

    func withdrawalFee(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<FiatValue> {
        withdrawFeeAndLimit(for: currency, paymentMethodType: paymentMethodType)
            .map(\.fee)
    }

    func withdrawalMinAmount(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<FiatValue> {
        withdrawFeeAndLimit(for: currency, paymentMethodType: paymentMethodType)
            .map(\.minLimit)
    }

    func withdrawal(for checkout: WithdrawalCheckoutData) -> Single<Result<FiatValue, Error>> {
        client.withdraw(data: checkout)
            .asSingle()
            .mapToResult { response -> FiatValue in
                guard let amount = FiatValue.create(major: response.amount.value, currency: checkout.currency) else {
                    fatalError("Couldn't create FiatValue from withdrawal response: \(response)")
                }
                return amount
            }
    }
}
