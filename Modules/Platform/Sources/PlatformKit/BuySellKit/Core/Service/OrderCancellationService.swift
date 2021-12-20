// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import NabuNetworkError
import RxSwift

public enum OrderCancellationError: Error {
    case network(NabuNetworkError)
}

public protocol OrderCancellationServiceAPI: AnyObject {

    /// Cancels and order with passed-in identifier
    func cancelOrder(with identifier: String) -> AnyPublisher<Void, OrderCancellationError>

    /// Cancels an order associated with the given id
    func cancel(order id: String) -> Completable
}

final class OrderCancellationService: OrderCancellationServiceAPI {

    // MARK: - Injected

    private let client: OrderCancellationClientAPI
    private let orderDetailsService: OrdersServiceAPI

    // MARK: - Setup

    init(
        client: OrderCancellationClientAPI = resolve(),
        orderDetailsService: OrdersServiceAPI = resolve()
    ) {
        self.client = client
        self.orderDetailsService = orderDetailsService
    }

    // MARK: - Exposed

    func cancelOrder(with identifier: String) -> AnyPublisher<Void, OrderCancellationError> {
        client
            .cancel(order: identifier)
            .mapError(OrderCancellationError.network)
            .eraseToAnyPublisher()
    }

    func cancel(order id: String) -> Completable {
        // Cancel the order
        client.cancel(order: id)
            .asObservable()
            .ignoreElements()
            .asCompletable()
            // Fetch the orders anew
            .andThen(orderDetailsService.fetchOrders())
            .asCompletable()
    }
}
