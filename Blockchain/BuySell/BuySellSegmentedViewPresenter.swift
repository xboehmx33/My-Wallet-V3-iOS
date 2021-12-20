// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import DIKit
import FeatureDashboardUI
import FeatureTransactionDomain
import FeatureTransactionUI
import Foundation
import PlatformKit
import PlatformUIKit
import RIBs
import RxRelay
import SwiftUI
import ToolKit

final class BuySellSegmentedViewPresenter: SegmentedViewScreenPresenting {

    // MARK: - Types

    private typealias LocalizedStrings = LocalizationConstants.BuySellScreen

    // MARK: - Properties

    let leadingButton: Screen.Style.LeadingButton = .drawer

    let leadingButtonTapRelay: PublishRelay<Void> = .init()

    let trailingButton: Screen.Style.TrailingButton = .none

    let trailingButtonTapRelay: PublishRelay<Void> = .init()

    let barStyle: Screen.Style.Bar = .lightContent()

    let segmentedViewLocation: SegmentedViewScreenLocation = .top(.text(value: LocalizedStrings.title))

    private(set) lazy var segmentedViewModel: SegmentedViewModel = .primary(
        items: createSegmentedViewModelItems()
    )

    private(set) lazy var items: [SegmentedViewScreenItem] = {
        // Buy
        let buyListViewController = PricesViewController(
            presenter: PricesScreenPresenter(
                drawerRouter: NoDrawer(),
                interactor: PricesScreenInteractor(
                    showSupportedPairsOnly: true
                )
            ),
            customSelectionActionClosure: { [weak self] currency in
                guard let self = self else { return }
                self.coincore.cryptoAccounts(for: currency, filter: .custodial)
                    .ignoreFailure()
                    .receive(on: DispatchQueue.main)
                    .flatMap { [weak self] accounts -> AnyPublisher<TransactionFlowResult, Never> in
                        guard let self = self, let account = accounts.first else {
                            return Just(.abandoned).eraseToAnyPublisher()
                        }
                        return self.transactionsRouter.presentTransactionFlow(to: .buy(account))
                    }
                    .sink { result in
                        "\(result)".peek("🧾 \(#function)")
                    }
                    .store(in: &self.cancellables)
            }
        )
        buyListViewController.automaticallyApplyNavigationBarStyle = false

        // Sell
        let accountPickerBuilder = AccountPickerBuilder(
            singleAccountsOnly: true,
            action: .sell
        )
        let accountPickerDidSelect: AccountPickerDidSelect = { [weak self] account in
            guard let self = self else { return }
            guard let cryptoAccount = account as? CryptoAccount else {
                return
            }
            self.transactionsRouter.presentTransactionFlow(to: .sell(cryptoAccount))
                .sink { result in
                    "\(result)".peek("🧾 \(#function)")
                }
                .store(in: &self.cancellables)
        }
        let accountPickerRouter = accountPickerBuilder.build(
            listener: .simple(accountPickerDidSelect),
            navigationModel: ScreenNavigationModel.AccountPicker.modal(),
            headerModel: .none
        )
        mimicRIBAttachment(router: accountPickerRouter)

        return [
            SegmentedViewScreenItem(
                title: LocalizedStrings.buyTitle,
                viewController: buyListViewController
            ),
            SegmentedViewScreenItem(
                title: LocalizedStrings.sellTitle,
                viewController: accountPickerRouter.viewControllable.uiviewController
            )
        ]
    }()

    private func mimicRIBAttachment(router: RIBs.Routing) {
        currentRIBRouter?.interactable.deactivate()
        currentRIBRouter = router
        router.load()
        router.interactable.activate()
    }

    let itemIndexSelectedRelay: BehaviorRelay<(index: Int, animated: Bool)> = .init(value: (index: 0, animated: false))

    // MARK: - Private Properties

    private let transactionsRouter: TransactionsRouterAPI
    private let cryptoCurrenciesService: CryptoCurrenciesServiceAPI
    private let coincore: CoincoreAPI

    /// Currently retained RIBs router in use.
    private var currentRIBRouter: RIBs.Routing?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        cryptoCurrenciesService: CryptoCurrenciesServiceAPI = resolve(),
        transactionsRouter: TransactionsRouterAPI = resolve(),
        coincore: CoincoreAPI = resolve()
    ) {
        self.transactionsRouter = transactionsRouter
        self.cryptoCurrenciesService = cryptoCurrenciesService
        self.coincore = coincore
    }
}

extension UIViewController: SegmentedViewScreenViewController {
    public func adjustInsetForBottomButton(withHeight height: CGFloat) {}
}
