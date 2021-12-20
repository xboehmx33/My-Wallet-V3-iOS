// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Foundation
import Localization
import PlatformUIKit
import RxRelay
import RxSwift
import ToolKit

final class DashboardSegmentedViewScreenPresenter: SegmentedViewScreenPresenting {

    // MARK: - Types

    private typealias LocalizedString = LocalizationConstants.DashboardScreen

    // MARK: - Properties

    let leadingButton: Screen.Style.LeadingButton = .drawer

    let leadingButtonTapRelay: PublishRelay<Void> = .init()

    let trailingButton: Screen.Style.TrailingButton

    let trailingButtonTapRelay: PublishRelay<Void> = .init()

    let barStyle: Screen.Style.Bar = .lightContent()

    let segmentedViewLocation: SegmentedViewScreenLocation = .top(.text(value: LocalizedString.title))

    private(set) lazy var segmentedViewModel: SegmentedViewModel = .primary(
        items: createSegmentedViewModelItems()
    )

    private(set) lazy var items: [SegmentedViewScreenItem] = [
        SegmentedViewScreenItem(
            title: LocalizedString.portfolio,
            viewController: PortfolioViewController(
                fiatBalanceCellProvider: fiatBalanceCellProvider,
                presenter: dashboardScreenPresenter
            )
        ),
        SegmentedViewScreenItem(
            title: LocalizedString.prices,
            viewController: PricesViewController(
                presenter: PricesScreenPresenter(
                    interactor: PricesScreenInteractor(
                        showSupportedPairsOnly: false
                    )
                )
            )
        )
    ]

    let itemIndexSelectedRelay: BehaviorRelay<(index: Int, animated: Bool)> = .init(value: (index: 0, animated: false))

    // MARK: - Private Properties

    private let dashboardScreenPresenter: PortfolioScreenPresenter
    private let fiatBalanceCellProvider: FiatBalanceCellProviding
    private let drawerRouter: DrawerRouting
    private let disposeBag = DisposeBag()
    private var qrCodeScannerRouter: QRCodeScannerRouting

    // MARK: - Init

    init(
        drawerRouter: DrawerRouting,
        fiatBalanceCellProvider: FiatBalanceCellProviding,
        dashboardScreenPresenter: PortfolioScreenPresenter,
        qrCodeScannerRouter: QRCodeScannerRouting
    ) {
        self.drawerRouter = drawerRouter
        self.fiatBalanceCellProvider = fiatBalanceCellProvider
        self.dashboardScreenPresenter = dashboardScreenPresenter
        self.qrCodeScannerRouter = qrCodeScannerRouter
        trailingButton = .qrCode

        leadingButtonTapRelay
            .bindAndCatch(weak: self) { (self) in
                self.drawerRouter.toggleSideMenu()
            }
            .disposed(by: disposeBag)

        trailingButtonTapRelay
            .bindAndCatch(weak: self) { (self) in
                self.qrCodeScannerRouter.showQRCodeScanner()
            }
            .disposed(by: disposeBag)
    }
}
