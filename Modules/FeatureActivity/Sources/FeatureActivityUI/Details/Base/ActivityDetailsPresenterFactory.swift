// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import ERC20Kit
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxRelay
import RxSwift
import ToolKit

enum ActivityDetailsPresenterFactory {

    static func presenter(
        for event: ActivityItemEvent,
        router: ActivityRouterAPI
    ) -> DetailsScreenPresenterAPI {
        switch event {
        case .interest(let interest):
            return InterestActivityDetailsPresenter(event: interest)
        case .fiat(let fiat):
            return FiatActivityDetailsPresenter(event: fiat)
        case .crypto(let crypto):
            return CryptoActivityDetailsPresenter(event: crypto)
        case .buySell(let buySell):
            return BuySellActivityDetailsPresenter(event: buySell)
        case .swap(let swap):
            return SwapActivityDetailsPresenter(event: swap)
        case .transactional(let transactional):
            switch transactional.currency {
            case .coin(let model):
                return Self.presenter(model: model, transactional: transactional, router: router)
            case .erc20:
                let interactor = ERC20ActivityDetailsInteractor(cryptoCurrency: transactional.currency)
                return ERC20ActivityDetailsPresenter(event: transactional, router: router, interactor: interactor)
            case .celoToken:
                fatalError("Transactional Activity Details not implemented for \(transactional.currency.code).")
            }
        }
    }

    private static func presenter(
        model: AssetModel,
        transactional: TransactionalActivityItemEvent,
        router: ActivityRouterAPI
    ) -> DetailsScreenPresenterAPI {
        switch model.code {
        case NonCustodialCoinCode.bitcoin.rawValue:
            return BitcoinActivityDetailsPresenter(event: transactional, router: router)
        case NonCustodialCoinCode.bitcoinCash.rawValue:
            return BitcoinCashActivityDetailsPresenter(event: transactional, router: router)
        case NonCustodialCoinCode.stellar.rawValue:
            return StellarActivityDetailsPresenter(event: transactional, router: router)
        case NonCustodialCoinCode.ethereum.rawValue:
            return EthereumActivityDetailsPresenter(event: transactional, router: router)
        default:
            fatalError("Transactional Activity Details not implemented for \(transactional.currency.code).")
        }
    }
}
