// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import RxSwift

public protocol CustodialAddressServiceAPI {
    func receiveAddress(for cryptoCurrency: CryptoCurrency) -> Single<String>
}

final class CustodialAddressService: CustodialAddressServiceAPI {

    private let client: CustodialPaymentAccountClientAPI

    // MARK: - Setup

    init(client: CustodialPaymentAccountClientAPI = resolve()) {
        self.client = client
    }

    func receiveAddress(for cryptoCurrency: CryptoCurrency) -> Single<String> {
        client.custodialPaymentAccount(for: cryptoCurrency)
            .map(\.account)
            .map(\.address)
            .asSingle()
    }
}
