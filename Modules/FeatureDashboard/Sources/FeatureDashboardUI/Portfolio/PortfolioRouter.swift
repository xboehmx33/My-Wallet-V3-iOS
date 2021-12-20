// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxRelay
import RxSwift

final class PortfolioRouter {

    private let accountsRouter: AccountsRouting
    private let disposeBag = DisposeBag()
    private let exchangeProviding: ExchangeProviding
    private let navigationRouter: NavigationRouterAPI

    init(
        navigationRouter: NavigationRouterAPI = NavigationRouter(),
        exchangeProviding: ExchangeProviding = resolve(),
        accountsRouter: AccountsRouting = resolve()
    ) {
        self.accountsRouter = accountsRouter
        self.navigationRouter = navigationRouter
        self.exchangeProviding = exchangeProviding
    }

    func showWalletActionScreen(for account: BlockchainAccount) {
        accountsRouter.route(to: account)
    }

    func showDetailsScreen(for currency: CryptoCurrency) {
        let builder = AssetDetailsBuilder(
            accountsRouter: accountsRouter,
            currency: currency,
            exchangeProviding: exchangeProviding
        )
        let controller = builder.build()
        navigationRouter.present(
            viewController: controller,
            using: .modalOverTopMost
        )
    }
}
