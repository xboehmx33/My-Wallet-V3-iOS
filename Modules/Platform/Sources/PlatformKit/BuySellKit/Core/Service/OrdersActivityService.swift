// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import RxSwift
import ToolKit

final class OrdersActivityService: OrdersActivityServiceAPI {

    private let client: OrdersActivityClientAPI
    private let fiatCurrencyService: FiatCurrencyServiceAPI
    private let priceService: PriceServiceAPI
    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    private let cache: Cache<CurrencyType, OrdersActivityResponse>

    init(
        client: OrdersActivityClientAPI = resolve(),
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()
    ) {
        self.client = client
        self.fiatCurrencyService = fiatCurrencyService
        self.priceService = priceService
        self.enabledCurrenciesService = enabledCurrenciesService
        cache = Cache(entryLifetime: 90)
    }

    func activity(fiatCurrency: FiatCurrency) -> Single<[CustodialActivityEvent.Fiat]> {
        guard let response = cache.value(forKey: fiatCurrency.currencyType) else {
            return client.activityResponse(currency: fiatCurrency)
                .asSingle()
                .do(onSuccess: { [cache] response in
                    cache.set(response, forKey: fiatCurrency.currencyType)
                })
                .map { response in
                    response
                        .items
                        .compactMap(CustodialActivityEvent.Fiat.init)
                        .filter { $0.paymentError == nil }
                }
        }
        let items = response
            .items
            .compactMap(CustodialActivityEvent.Fiat.init)
            .filter { $0.paymentError == nil }
        return .just(items)
    }

    func activity(cryptoCurrency: CryptoCurrency) -> Single<[CustodialActivityEvent.Crypto]> {
        guard let response = cache.value(forKey: cryptoCurrency.currencyType) else {
            return client.activityResponse(currency: cryptoCurrency)
                .asSingle()
                .do(onSuccess: { [cache] response in
                    cache.set(response, forKey: cryptoCurrency.currencyType)
                })
                .flatMap { [fromResponse] response in
                    fromResponse(response, cryptoCurrency)
                }
        }

        return fromResponse(response: response, cryptoCurrency: cryptoCurrency)
    }

    private func fromResponse(
        response: OrdersActivityResponse,
        cryptoCurrency: CryptoCurrency
    ) -> Single<[CustodialActivityEvent.Crypto]> {
        Observable.combineLatest(
            response.items.map { item in
                price(of: cryptoCurrency, insertedAt: item.insertedAt)
                    .compactMap { [enabledCurrenciesService] price in
                        CustodialActivityEvent.Crypto(
                            item: item,
                            price: price.moneyValue.fiatValue!,
                            enabledCurrenciesService: enabledCurrenciesService
                        )
                    }
                    .asObservable()
            }
        )
        .asSingle()
    }

    private func price(of cryptoCurrency: CryptoCurrency, insertedAt: String) -> Single<FiatValue> {
        let date: Date = DateFormatter.sessionDateFormat.date(from: insertedAt)
            ?? DateFormatter.iso8601Format.date(from: insertedAt)
            ?? Date()
        return fiatCurrencyService.displayCurrency
            .flatMap { [priceService] fiatCurrency in
                priceService.price(of: cryptoCurrency, in: fiatCurrency, at: .time(date))
                    .map(\.moneyValue.fiatValue!)
            }
            .asSingle()
    }
}
