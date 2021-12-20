// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxRelay
import RxSwift

final class BuySellActivityItemEventService: BuySellActivityItemEventServiceAPI {

    private let ordersService: OrdersServiceAPI
    private let kycTiersService: KYCTiersServiceAPI
    private var isTier2Approved: Single<Bool> {
        kycTiersService
            .tiers
            .asSingle()
            .map(\.isTier2Approved)
            .catchErrorJustReturn(false)
    }

    init(
        ordersService: OrdersServiceAPI = resolve(),
        kycTiersService: KYCTiersServiceAPI = resolve()
    ) {
        self.ordersService = ordersService
        self.kycTiersService = kycTiersService
    }

    func buySellActivityEvents(cryptoCurrency: CryptoCurrency) -> Single<[BuySellActivityItemEvent]> {
        isTier2Approved
            .flatMap(weak: self) { (self, isTier2Approved) in
                guard isTier2Approved else {
                    return Single.just([])
                }
                return self.fetchBuySellActivityEvents(cryptoCurrency: cryptoCurrency)
            }
    }

    private func fetchBuySellActivityEvents(cryptoCurrency: CryptoCurrency) -> Single<[BuySellActivityItemEvent]> {
        ordersService
            .orders
            .map { orders -> [OrderDetails] in
                orders.filter {
                    $0.outputValue.currency == cryptoCurrency || $0.inputValue.currency == cryptoCurrency
                }
            }
            .map { items in items.map { BuySellActivityItemEvent(with: $0) } }
    }
}
