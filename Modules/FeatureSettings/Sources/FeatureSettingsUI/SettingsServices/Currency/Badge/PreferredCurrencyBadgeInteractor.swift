// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import PlatformUIKit
import RxRelay
import RxSwift

final class PreferredCurrencyBadgeInteractor: DefaultBadgeAssetInteractor {

    // MARK: - Setup

    init(
        settingsService: SettingsServiceAPI,
        fiatCurrencyService: FiatCurrencySettingsServiceAPI
    ) {
        super.init()
        let settingsFiatCurrency = settingsService.valueObservable
            .map(\.displayCurrency)
        let fiatCurrency = fiatCurrencyService.displayCurrencyPublisher
            .asObservable()

        Observable
            .combineLatest(settingsFiatCurrency, fiatCurrency) { (remoteFiatCurrency: $0, localFiatCurrency: $1) }
            .map { payload -> FiatCurrency? in
                guard let remoteFiatCurrency = payload.remoteFiatCurrency else {
                    // We don't recognise the value select on Backend
                    return payload.localFiatCurrency
                }
                guard remoteFiatCurrency == payload.localFiatCurrency else {
                    // Currencies don't match, we must wait them to load.
                    return nil
                }
                // We recognise the value and it matches the current value.
                return remoteFiatCurrency
            }
            .map { fiatCurrency -> BadgeItem? in
                guard let fiatCurrency = fiatCurrency else {
                    return nil
                }
                let title = "\(fiatCurrency.name) (\(fiatCurrency.displaySymbol))"
                return BadgeItem(
                    type: .default(accessibilitySuffix: title),
                    description: title
                )
            }
            .map { badgeItem in
                guard let badgeItem = badgeItem else {
                    return .loading
                }
                return .loaded(next: badgeItem)
            }
            .catchErrorJustReturn(.loading)
            .bindAndCatch(to: stateRelay)
            .disposed(by: disposeBag)
    }
}
