// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

/// A CryptoAccount, NonCustodialAccount object used by Receive screen to display currencies that are not yet currently loaded.
final class ReceivePlaceholderCryptoAccount: CryptoAccount, NonCustodialAccount {
    var asset: CryptoCurrency

    var isDefault: Bool = true

    var identifier: AnyHashable = UUID().uuidString

    var balance: Single<MoneyValue> {
        .just(.zero(currency: asset))
    }

    var pendingBalance: Single<MoneyValue> {
        .just(.zero(currency: asset))
    }

    var actions: Single<AvailableActions> {
        .just([])
    }

    var activity: Single<[ActivityItemEvent]> {
        .just([])
    }

    var isFunded: Single<Bool> {
        .just(false)
    }

    func balancePair(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValuePair, Error> {
        .just(.zero(baseCurrency: asset.currencyType, quoteCurrency: fiatCurrency.currencyType))
    }

    func can(perform action: AssetAction) -> Single<Bool> {
        .just(true)
    }

    var receiveAddress: Single<ReceiveAddress> {
        .error(ReceiveAddressError.notSupported)
    }

    var actionableBalance: Single<MoneyValue> {
        .just(.zero(currency: asset))
    }

    var requireSecondPassword: Single<Bool> {
        .just(false)
    }

    var label: String {
        asset.defaultWalletName
    }

    init(
        asset: CryptoCurrency
    ) {
        self.asset = asset
    }

    func invalidateAccountBalance() {
        // NO-OP
    }
}
