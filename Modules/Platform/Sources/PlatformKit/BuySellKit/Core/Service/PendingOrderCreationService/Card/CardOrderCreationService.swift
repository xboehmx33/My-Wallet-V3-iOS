// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import RxSwift

final class CardOrderCreationService: PendingOrderCreationServiceAPI {

    private let orderQuoteService: OrderQuoteServiceAPI
    private let orderCreationService: OrderCreationServiceAPI

    init(
        orderQuoteService: OrderQuoteServiceAPI = resolve(),
        orderCreationService: OrderCreationServiceAPI = resolve()
    ) {
        self.orderQuoteService = orderQuoteService
        self.orderCreationService = orderCreationService
    }

    func create(using candidateOrderDetails: CandidateOrderDetails) -> Single<PendingConfirmationCheckoutData> {
        let paymentMethod = candidateOrderDetails.paymentMethod?.method
        let quote = orderQuoteService.getQuote(
            query: QuoteQuery(
                profile: .simpleBuy,
                sourceCurrency: candidateOrderDetails.fiatCurrency,
                destinationCurrency: candidateOrderDetails.cryptoCurrency,
                amount: MoneyValue(fiatValue: candidateOrderDetails.fiatValue),
                paymentMethod: paymentMethod?.rawType,
                paymentMethodId: (paymentMethod?.isBankTransfer ?? false) ? candidateOrderDetails.paymentMethodId : nil
            )
        )
        let creation = orderCreationService.create(using: candidateOrderDetails)
        return Single
            .zip(quote, creation)
            .map { quote, checkoutData in
                PendingConfirmationCheckoutData(quote: quote, checkoutData: checkoutData)
            }
    }
}
