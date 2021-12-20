// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinKit
import DIKit
import MoneyKit
import PlatformKit
import RxSwift

final class BitcoinActivityDetailsInteractor {

    private let fiatCurrencySettings: FiatCurrencySettingsServiceAPI
    private let priceService: PriceServiceAPI
    private let detailsService: AnyActivityItemEventDetailsFetcher<BitcoinActivityItemEventDetails>
    private let wallet: BitcoinWalletBridgeAPI

    init(
        wallet: BitcoinWalletBridgeAPI = resolve(),
        fiatCurrencySettings: FiatCurrencySettingsServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        detailsService: AnyActivityItemEventDetailsFetcher<BitcoinActivityItemEventDetails> = resolve()
    ) {
        self.detailsService = detailsService
        self.fiatCurrencySettings = fiatCurrencySettings
        self.priceService = priceService
        self.wallet = wallet
    }

    private func note(for identifier: String) -> Single<String?> {
        wallet.note(for: identifier)
    }

    func updateNote(for identifier: String, to note: String?) -> Completable {
        wallet.updateNote(for: identifier, note: note)
    }

    private func price(at date: Date) -> Single<PriceQuoteAtTime> {
        fiatCurrencySettings
            .displayCurrency
            .asSingle()
            .flatMap(weak: self) { (self, fiatCurrency) in
                self.price(at: date, in: fiatCurrency)
            }
    }

    private func price(at date: Date, in fiatCurrency: FiatCurrency) -> Single<PriceQuoteAtTime> {
        priceService.price(
            of: CurrencyType.crypto(.coin(.bitcoin)),
            in: fiatCurrency,
            at: .time(date)
        )
        .asSingle()
    }

    func details(identifier: String, createdAt: Date) -> Observable<BitcoinActivityDetailsViewModel> {
        let transaction = detailsService
            .details(for: identifier)
        let note = note(for: identifier)
            .catchAndReturn(nil)
        let price = price(at: createdAt)
            .optional()
            .catchAndReturn(nil)

        return Observable
            .combineLatest(
                transaction,
                price.asObservable(),
                note.asObservable()
            )
            .map { BitcoinActivityDetailsViewModel(details: $0, price: $1?.moneyValue.fiatValue, note: $2) }
    }
}
