// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import RxSwift
import RxToolKit
import ToolKit

public protocol SwapActivityServiceAPI: AnyObject {
    func fetchActivity(
        cryptoCurrency: CryptoCurrency,
        directions: Set<OrderDirection>
    ) -> Single<[SwapActivityItemEvent]>
}

final class SwapActivityService: SwapActivityServiceAPI {

    private let client: SwapClientAPI
    private let fiatCurrencyProvider: FiatCurrencySettingsServiceAPI
    private let cache: CachedValue<[SwapActivityItemEvent]>

    init(
        client: SwapClientAPI = resolve(),
        fiatCurrencyProvider: CompleteSettingsServiceAPI = resolve()
    ) {
        self.fiatCurrencyProvider = fiatCurrencyProvider
        self.client = client
        cache = CachedValue(
            configuration: .periodic(
                seconds: 30,
                schedulerIdentifier: "SwapActivityService"
            )
        )
        cache.setFetch {
            fiatCurrencyProvider.displayCurrency
                .asSingle()
                .flatMap { fiatCurrency -> Single<[SwapActivityItemEvent]> in
                    client.fetchActivity(
                        from: Date(),
                        fiatCurrency: fiatCurrency.code,
                        cryptoCurrency: nil,
                        limit: 50
                    )
                    .asSingle()
                }
        }
    }

    func fetchActivity(
        cryptoCurrency: CryptoCurrency,
        directions: Set<OrderDirection>
    ) -> Single<[SwapActivityItemEvent]> {
        cache.valueSingle
            .map { events in
                events
                    .filter { event in
                        directions.contains(event.kind.direction)
                            && event.pair.inputCurrencyType == cryptoCurrency
                    }
            }
    }
}
