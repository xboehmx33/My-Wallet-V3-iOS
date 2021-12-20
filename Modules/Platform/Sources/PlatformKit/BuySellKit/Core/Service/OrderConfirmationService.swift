// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import RxSwift

/// Used to execute the order once created
public protocol OrderConfirmationServiceAPI: AnyObject {
    func confirm(checkoutData: CheckoutData) -> Single<CheckoutData>
}

final class OrderConfirmationService: OrderConfirmationServiceAPI {

    // MARK: - Service Error

    enum ServiceError: Error {
        case mappingError
    }

    // MARK: - Properties

    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let client: CardOrderConfirmationClientAPI

    // MARK: - Setup

    init(
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
        client: CardOrderConfirmationClientAPI = resolve()
    ) {
        self.analyticsRecorder = analyticsRecorder
        self.client = client
    }

    func confirm(checkoutData: CheckoutData) -> Single<CheckoutData> {
        let orderId = checkoutData.order.identifier
        let paymentMethodId = checkoutData.order.paymentMethodId
        let partner: OrderPayload.ConfirmOrder.Partner
        switch checkoutData.order.paymentMethod {
        case .bankAccount:
            partner = .bank
        case .bankTransfer:
            partner = .bank
        case .card:
            partner = .card(redirectURL: PartnerAuthorizationData.exitLink)
        case .funds:
            partner = .funds
        }

        return client.confirmOrder(
            with: orderId,
            partner: partner,
            paymentMethodId: paymentMethodId
        )
        .asSingle()
        .map(weak: self) { (self, response) in
            OrderDetails(recorder: self.analyticsRecorder, response: response)
        }
        .map { details -> OrderDetails in
            guard let details = details else {
                throw ServiceError.mappingError
            }
            return details
        }
        .map { checkoutData.checkoutData(byAppending: $0) }
    }
}
