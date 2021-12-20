// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import RxSwift

public protocol PortfolioProviding {
    var portfolio: Observable<Portfolio> { get }
}

public final class PortfolioProvider: PortfolioProviding {

    private let portfolioBalanceChangeProviding: PortfolioBalanceChangeProviding
    private let fiatCurrencyService: FiatCurrencyServiceAPI
    private let coincore: CoincoreAPI

    public init(
        coincore: CoincoreAPI,
        fiatCurrencyService: FiatCurrencyServiceAPI
    ) {
        self.fiatCurrencyService = fiatCurrencyService
        self.coincore = coincore
        portfolioBalanceChangeProviding = PortfolioBalanceChangeProvider(
            coincore: coincore,
            fiatCurrencyService: fiatCurrencyService
        )
    }

    // MARK: - PortfolioProviding

    public var portfolio: Observable<Portfolio> {
        let balancesObservable = Observable.combineLatest(
            balance(for: .coin(.ethereum)),
            balance(for: .coin(.stellar)),
            balance(for: .coin(.bitcoin)),
            balance(for: .coin(.bitcoinCash))
        )
        return Observable
            .combineLatest(
                balancesObservable,
                change,
                fiatCurrencyService.displayCurrencyPublisher.asObservable()
            )
            .map { accounts, change, fiatCurrency -> Portfolio in
                let (ethereum, stellar, bitcoin, bitcoinCash) = accounts
                return .init(
                    accounts: [
                        .coin(.ethereum): ethereum,
                        .coin(.stellar): stellar,
                        .coin(.bitcoin): bitcoin,
                        .coin(.bitcoinCash): bitcoinCash
                    ],
                    balanceChange: .init(
                        balance: change.balance.displayMajorValue,
                        changePercentage: change.changePercentage,
                        change: change.change.displayMajorValue
                    ),
                    fiatCurrency: fiatCurrency
                )
            }
    }

    // MARK: - PortfolioChange

    private var change: Observable<PortfolioBalanceChange> {
        portfolioBalanceChangeProviding
            .changeObservable
            .compactMap(\.value)
    }

    // MARK: - Balance Descriptions

    private func balance(for currency: CryptoCurrency) -> Observable<Portfolio.Account> {
        coincore[currency]
            .accountGroup(filter: .all)
            .asObservable()
            .flatMap(\.balance)
            .map(\.amount)
            .catchErrorJustReturn(.zero)
            .map(\.description)
            .map { Portfolio.Account(currency: currency, balance: $0) }
    }
}
