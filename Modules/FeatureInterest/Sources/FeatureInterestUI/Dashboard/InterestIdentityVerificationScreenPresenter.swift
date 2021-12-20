// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import DIKit
import Localization
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxSwift

public final class InterestIdentityVerificationScreenPresenter: InterestDashboardAnnouncementPresenting {

    private typealias LocalizationId = LocalizationConstants.Interest.Screen.IdentityVerification

    /// Returns the total count of cells
    public var cellCount: Int {
        cellArrangement.count
    }

    public let cellArrangement: [InterestAnnouncementCellType]

    let announcement: AnnouncementCardViewModel
    let notNowButtonViewModel: ButtonViewModel
    let verifyIdentityButtonViewModel: ButtonViewModel
    let badgeNumberedItemViewModels: [BadgeNumberedItemViewModel]

    private let router: InterestDashboardAnnouncementRouting
    private let disposeBag = DisposeBag()

    public init(router: InterestDashboardAnnouncementRouting) {
        self.router = router
        badgeNumberedItemViewModels = [
            .init(
                number: 1,
                title: LocalizationId.List.First.title,
                description: LocalizationId.List.First.description,
                descriptors: .dashboard(badgeAccessibilitySuffix: "1")
            ),
            .init(
                number: 2,
                title: LocalizationId.List.Second.title,
                description: LocalizationId.List.Second.description,
                descriptors: .dashboard(badgeAccessibilitySuffix: "2")
            ),
            .init(
                number: 3,
                title: LocalizationId.List.Third.title,
                description: LocalizationId.List.Third.description,
                descriptors: .dashboard(badgeAccessibilitySuffix: "3")
            )
        ]
        announcement = .init(
            badgeImage: .init(
                image: .local(name: Icon.interest.name, bundle: .componentLibrary),
                contentColor: .white,
                backgroundColor: .defaultBadge,
                cornerRadius: .round,
                size: .init(edge: 32.0)
            ),
            background: .init(color: .clear, imageName: "pcb_bg", bundle: .platformUIKit),
            border: .none,
            title: LocalizationId.title,
            description: LocalizationId.description,
            dismissState: .undismissible
        )

        notNowButtonViewModel = .secondary(with: LocalizationId.notNow)
        verifyIdentityButtonViewModel = .primary(with: LocalizationId.action)

        let badgedNumberedItems: [InterestAnnouncementCellType] = badgeNumberedItemViewModels.map { .numberedItem($0) }
        cellArrangement = [.announcement(announcement)] +
            badgedNumberedItems +
            [.buttons([notNowButtonViewModel, verifyIdentityButtonViewModel])]

        notNowButtonViewModel
            .tapRelay
            .bindAndCatch(weak: self) { (self) in
                self.router.dismiss(startKYC: false)
            }
            .disposed(by: disposeBag)

        verifyIdentityButtonViewModel
            .tapRelay
            .bindAndCatch(weak: self) { (self) in
                self.router.dismiss(startKYC: true)
            }
            .disposed(by: disposeBag)
    }
}
