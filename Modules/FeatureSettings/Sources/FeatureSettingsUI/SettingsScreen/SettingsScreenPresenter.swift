// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import PlatformUIKit
import RxRelay
import RxSwift

public final class SettingsScreenPresenter {

    // MARK: - Types

    typealias Section = SettingsSectionType

    // MARK: - Navigation Properties

    let trailingButton: Screen.Style.TrailingButton = .none

    var leadingButton: Screen.Style.LeadingButton {
        .none
    }

    let barStyle: Screen.Style.Bar = .lightContent()

    // MARK: - Public Properties

    var sectionObservable: Observable<[SettingsSectionViewModel]> {
        sectionsProvider.sections
    }

    var sectionArrangement: [Section] {
        sectionRelay.value
    }

    // MARK: - Cell Presenters

    let sectionsProvider: SettingsSectionsProvider

    // MARK: - Public

    let actionRelay = PublishRelay<SettingsScreenAction>()

    // MARK: Private Properties

    private unowned let router: SettingsRouterAPI
    private let sectionRelay = BehaviorRelay<[Section]>(value: Section.default)
    private let interactor: SettingsScreenInteractor
    private let disposeBag = DisposeBag()

    // MARK: - Section Presenters

    private let profileSectionPresenter: ProfileSectionPresenter
    private let preferencesSectionPresenter: PreferencesSectionPresenter
    private let connectPresenter: ConnectSectionPresenter
    private let securitySectionPresenter: SecuritySectionPresenter
    private let banksSectionPresenter: BanksSectionPresenter
    private let cardsSectionPresenter: CardsSectionPresenter
    private let helpSectionPresenter: HelpSectionPresenter

    // MARK: - Init

    public init(
        interactor: SettingsScreenInteractor,
        router: SettingsRouterAPI
    ) {
        helpSectionPresenter = HelpSectionPresenter()

        connectPresenter = .init(
            exchangeConnectionStatusProvider: interactor.pitConnnectionProviding
        )

        securitySectionPresenter = .init(
            smsTwoFactorService: interactor.smsTwoFactorService,
            credentialsStore: interactor.credentialsStore,
            biometryProvider: interactor.biometryProviding,
            settingsAuthenticater: interactor.settingsAuthenticating,
            recoveryPhraseStatusProvider: interactor.recoveryPhraseStatusProviding,
            balanceSharingService: interactor.balanceSharingService,
            authenticationCoordinator: interactor.authenticationCoordinator
        )

        cardsSectionPresenter = CardsSectionPresenter(
            interactor: interactor.cardSectionInteractor
        )

        banksSectionPresenter = BanksSectionPresenter(
            interactor: interactor.bankSectionInteractor
        )

        profileSectionPresenter = .init(
            tiersLimitsProvider: interactor.tiersProviding,
            emailVerificationInteractor: interactor.emailVerificationBadgeInteractor,
            mobileVerificationInteractor: interactor.mobileVerificationBadgeInteractor
        )

        preferencesSectionPresenter = .init(
            emailNotificationService: interactor.emailNotificationsService,
            preferredCurrencyBadgeInteractor: interactor.preferredCurrencyBadgeInteractor
        )

        sectionsProvider = SettingsSectionsProvider(
            about: helpSectionPresenter,
            connect: connectPresenter,
            banks: banksSectionPresenter,
            cards: cardsSectionPresenter,
            security: securitySectionPresenter,
            profile: profileSectionPresenter,
            preferences: preferencesSectionPresenter
        )

        self.router = router
        self.interactor = interactor

        setup()
    }

    // MARK: - Private

    private func setup() {
        actionRelay
            .bindAndCatch(to: router.actionRelay)
            .disposed(by: disposeBag)

        sectionsProvider
            .sections
            .observeOn(MainScheduler.instance)
            .map { $0.map(\.sectionType) }
            .bindAndCatch(to: sectionRelay)
            .disposed(by: disposeBag)
    }

    // MARK: - Public

    /// Should be called each time the `Settings` screen comes into view
    func refresh() {
        interactor.refresh()
    }

    // MARK: - Exposed

    func navigationBarLeadingButtonTapped() {
        router.previousRelay.accept(())
    }
}
