// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import NabuNetworkError
import PlatformKit

/// For testing purpose while waiting for backend. To be moved in the mock package.
class PaymentEligibleMethodsClientMock: PaymentEligibleMethodsClientAPI {

    func eligiblePaymentMethods(
        for currency: String,
        currentTier: KYC.Tier,
        sddEligibleTier: Int?
    ) -> AnyPublisher<[PaymentMethodsResponse.Method], NabuNetworkError> {
        .just([])
    }

    func paymentsCardAcquirers() -> AnyPublisher<[PaymentCardAcquirer], NabuNetworkError> {
        .just([
            PaymentCardAcquirer(
                cardAcquirerName: .stripe,
                cardAcquirerAccountCodes: ["stripe_uk", "stripe_us"],
                // swiftlint:disable line_length
                apiKey: "pk_test_51JhAakHxBe1tOCzxhX2cvybhcCPMMXfQQghkI7X9VEUFMTyLvcyLVFXSkM9bjsynKmRRwLwkalcPrWJeGaNriU6S00x8XQ9VLX"
            ),
            PaymentCardAcquirer(
                cardAcquirerName: .checkout,
                cardAcquirerAccountCodes: ["checkout_uk"],
                apiKey: "pk_sbox_eiq2rsadi5eambtzil662iccmil"
            )
        ])
    }
}
