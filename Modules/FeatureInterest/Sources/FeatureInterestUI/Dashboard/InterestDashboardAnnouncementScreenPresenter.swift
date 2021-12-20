// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import DIKit
import FeatureInterestDomain
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxSwift

public final class InterestDashboardAnnouncementScreenPresenter: InterestDashboardAnnouncementPresenting {

    private typealias AccessibilityId = Accessibility.Identifier.Interest.Dashboard.Announcement
    private typealias LocalizationId = LocalizationConstants.Interest.Screen.Announcement

    /// Returns the total count of cells
    public var cellCount: Int {
        cellArrangement.count
    }

    public let cellArrangement: [InterestAnnouncementCellType]

    let announcement: AnnouncementCardViewModel
    let visitButtonViewModel: ButtonViewModel
    let rateLineCellPresenter: LineItemCellPresenting
    let paymentIntervalCellPresenter: LineItemCellPresenting
    let footerCellPresenter: FooterTableViewCellPresenter

    private let router: InterestDashboardAnnouncementRouting
    private let disposeBag = DisposeBag()

    public init(
        router: InterestDashboardAnnouncementRouting,
        service: InterestAccountServiceAPI = resolve()
    ) {
        self.router = router
        announcement = .init(
            badgeImage: .init(
                image: .local(name: Icon.interest.name, bundle: .componentLibrary),
                contentColor: .white,
                backgroundColor: .defaultBadge,
                cornerRadius: .round,
                size: .init(edge: 32.0)
            ),
            border: .none,
            title: LocalizationId.title,
            description: LocalizationId.description,
            dismissState: .undismissible
        )

        let rates = DefaultLineItemCellInteractor(
            title: DefaultLabelContentInteractor(knownValue: LocalizationId.Cells.LineItem.Rate.title),
            description: InterestAccountDetailsDescriptionLabelInteractor.Rates(
                service: service,
                cryptoCurrency: .coin(.bitcoin)
            )
        )
        rateLineCellPresenter = DefaultLineItemCellPresenter(
            interactor: rates,
            accessibilityIdPrefix: "\(AccessibilityId.rateLineItem)"
        )
        paymentIntervalCellPresenter = DefaultLineItemCellPresenter(
            interactor: .init(
                title: DefaultLabelContentInteractor(knownValue: LocalizationId.Cells.LineItem.Interest.title),
                description: DefaultLabelContentInteractor(knownValue: LocalizationId.Cells.LineItem.Interest.description)
            ),
            accessibilityIdPrefix: "\(AccessibilityId.paymentIntervalLineItem)"
        )
        footerCellPresenter = .init(
            text: LocalizationId.Cells.Footer.title,
            accessibility: .id(AccessibilityId.footerCell)
        )
        visitButtonViewModel = .secondary(with: LocalizationId.Cells.Button.title)

        cellArrangement = [
            .announcement(announcement),
            .item(rateLineCellPresenter),
            .item(paymentIntervalCellPresenter),
            .buttons([visitButtonViewModel]),
            .footer(footerCellPresenter)
        ]

        visitButtonViewModel
            .tapRelay
            .bindAndCatch(weak: self) { (self) in
                self.router.visitBlockchainTapped()
            }
            .disposed(by: disposeBag)
    }
}
