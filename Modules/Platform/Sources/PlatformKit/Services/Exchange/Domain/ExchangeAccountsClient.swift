// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import NabuNetworkError
import NetworkKit

protocol ExchangeAccountsProviderClientAPI {

    func exchangeAddress(
        with currency: CryptoCurrency
    ) -> AnyPublisher<CryptoExchangeAddressResponse, NabuNetworkError>
}

protocol ExchangeAccountsClientAPI: ExchangeAccountsProviderClientAPI {}

final class ExchangeAccountsClient: ExchangeAccountsClientAPI {

    private enum Path {
        static let exchangeAddress = ["payments", "accounts", "linked"]
    }

    // MARK: - Properties

    private let networkAdapter: NetworkAdapterAPI
    private let requestBuilder: RequestBuilder

    // MARK: - Setup

    init(
        networkAdapter: NetworkAdapterAPI = resolve(tag: DIKitContext.retail),
        requestBuilder: RequestBuilder = resolve(tag: DIKitContext.retail)
    ) {
        self.networkAdapter = networkAdapter
        self.requestBuilder = requestBuilder
    }

    // MARK: - ExchangeAccountsClientAPI

    func exchangeAddress(
        with currency: CryptoCurrency
    ) -> AnyPublisher<CryptoExchangeAddressResponse, NabuNetworkError> {
        let model = CryptoExchangeAddressRequest(currency: currency)
        let request = requestBuilder.put(
            path: Path.exchangeAddress,
            body: try? JSONEncoder().encode(model),
            authenticated: true
        )!
        return networkAdapter.perform(request: request)
    }
}
