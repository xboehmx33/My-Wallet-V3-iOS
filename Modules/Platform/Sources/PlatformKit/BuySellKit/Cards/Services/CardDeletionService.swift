// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import RxSwift
import RxToolKit
import ToolKit

public protocol PaymentMethodDeletionServiceAPI: AnyObject {
    /// Deletes a payment-method with a given removal data
    func delete(by data: PaymentMethodRemovalData) -> Completable
}

final class CardDeletionService: PaymentMethodDeletionServiceAPI {

    // MARK: - Private Properties

    private let client: CardDeletionClientAPI
    private let cardListService: CardListServiceAPI
    private let paymentMethodTypesService: PaymentMethodTypesServiceAPI

    // MARK: - Setup

    init(
        client: CardDeletionClientAPI = resolve(),
        cardListService: CardListServiceAPI = resolve(),
        paymentMethodTypesService: PaymentMethodTypesServiceAPI = resolve()
    ) {
        self.client = client
        self.cardListService = cardListService
        self.paymentMethodTypesService = paymentMethodTypesService
    }

    func delete(by data: PaymentMethodRemovalData) -> Completable {
        client
            .deleteCard(by: data.id)
            .asObservable()
            .ignoreElements()
            .asCompletable()
            .andThen(cardListService.fetchCards())
            .do(onSuccess: { [weak self] _ in
                self?.paymentMethodTypesService.clearPreferredPaymentIfNeeded(by: data.id)
            })
            .asCompletable()
    }
}
