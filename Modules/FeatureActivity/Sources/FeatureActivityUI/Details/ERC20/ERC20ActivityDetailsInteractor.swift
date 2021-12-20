// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import EthereumKit
import MoneyKit
import PlatformKit
import RxSwift

final class ERC20ActivityDetailsInteractor {

    // MARK: - Private Properties

    private let fiatCurrencySettings: FiatCurrencySettingsServiceAPI
    private let priceService: PriceServiceAPI
    private let detailsService: AnyActivityItemEventDetailsFetcher<EthereumActivityItemEventDetails>
    private let wallet: EthereumWalletBridgeAPI
    private let cryptoCurrency: CryptoCurrency

    // MARK: - Init

    init(
        wallet: EthereumWalletBridgeAPI = resolve(),
        fiatCurrencySettings: FiatCurrencySettingsServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        detailsService: AnyActivityItemEventDetailsFetcher<EthereumActivityItemEventDetails> = resolve(),
        cryptoCurrency: CryptoCurrency
    ) {
        self.cryptoCurrency = cryptoCurrency
        self.detailsService = detailsService
        self.fiatCurrencySettings = fiatCurrencySettings
        self.priceService = priceService
        self.wallet = wallet
    }

    // MARK: - Public Functions

    func details(identifier: String, createdAt: Date) -> Observable<ERC20ActivityDetailsViewModel> {
        let transaction = detailsService
            .details(for: identifier)
        let price = price(of: cryptoCurrency, at: createdAt)
            .optional()
            .catchAndReturn(nil)
        let feePrice = self.price(of: .coin(.ethereum), at: createdAt)
            .optional()
            .catchAndReturn(nil)

        return Observable
            .combineLatest(
                transaction,
                price.asObservable(),
                feePrice.asObservable()
            )
            .map {
                ERC20ActivityDetailsViewModel(
                    details: $0,
                    price: $1?.moneyValue.fiatValue,
                    feePrice: $2?.moneyValue.fiatValue
                )
            }
    }

    // MARK: - Private Functions

    private func price(of cryptoCurrency: CryptoCurrency, at date: Date) -> Single<PriceQuoteAtTime> {
        fiatCurrencySettings
            .displayCurrency
            .asSingle()
            .flatMap(weak: self) { (self, fiatCurrency) in
                self.price(of: cryptoCurrency, in: fiatCurrency, at: date)
            }
    }

    private func price(
        of cryptoCurrency: CryptoCurrency,
        in fiatCurrency: FiatCurrency,
        at date: Date
    ) -> Single<PriceQuoteAtTime> {
        priceService.price(
            of: cryptoCurrency,
            in: fiatCurrency,
            at: .time(date)
        )
        .asSingle()
    }
}
