// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit

public final class SettingsScreenInteractor {

    // MARK: - Interactors

    let emailVerificationBadgeInteractor: EmailVerificationBadgeInteractor
    let mobileVerificationBadgeInteractor: MobileVerificationBadgeInteractor
    let twoFactorVerificationBadgeInteractor: TwoFactorVerificationBadgeInteractor
    let preferredCurrencyBadgeInteractor: PreferredCurrencyBadgeInteractor
    let cardSectionInteractor: CardSettingsSectionInteractor
    let bankSectionInteractor: BanksSettingsSectionInteractor

    // MARK: - Services

    // TODO: All interactors should be created inside this class,
    /// and services should be injected into them through the main class.
    /// The presenter should not contain any interaction logic

    let settingsService: SettingsServiceAPI
    let smsTwoFactorService: SMSTwoFactorSettingsServiceAPI
    let emailNotificationsService: EmailNotificationSettingsServiceAPI

    let pitConnnectionProviding: PITConnectionStatusProviding
    let balanceSharingService: BalanceSharingSettingsServiceAPI
    let tiersProviding: TierLimitsProviding
    let settingsAuthenticating: AppSettingsAuthenticating
    let biometryProviding: BiometryProviding
    let credentialsStore: CredentialsStoreAPI
    let appSettings: BlockchainSettings.App
    let recoveryPhraseStatusProviding: RecoveryPhraseStatusProviding
    let authenticationCoordinator: AuthenticationCoordinating

    // MARK: - Private Properties

    private let disposeBag = DisposeBag()

    public init(
        balanceSharingService: BalanceSharingSettingsServiceAPI = resolve(),
        credentialsStore: CredentialsStoreAPI = resolve(),
        featureConfigurator: FeatureConfiguring = resolve(),
        settingsService: SettingsServiceAPI = resolve(),
        smsTwoFactorService: SMSTwoFactorSettingsServiceAPI = resolve(),
        emailNotificationService: EmailNotificationSettingsServiceAPI = resolve(),
        appSettings: BlockchainSettings.App = resolve(),
        fiatCurrencyService: FiatCurrencySettingsServiceAPI = resolve(),
        pitConnectionAPI: PITConnectionStatusProviding,
        settingsAuthenticating: AppSettingsAuthenticating = resolve(),
        tiersProviding: TierLimitsProviding = resolve(),
        wallet: WalletRecoveryVerifing,
        paymentMethodTypesService: PaymentMethodTypesServiceAPI,
        authenticationCoordinator: AuthenticationCoordinating
    ) {
        self.smsTwoFactorService = smsTwoFactorService
        self.appSettings = appSettings
        self.settingsService = settingsService
        emailNotificationsService = emailNotificationService
        self.tiersProviding = tiersProviding
        self.balanceSharingService = balanceSharingService

        cardSectionInteractor = CardSettingsSectionInteractor(
            paymentMethodTypesService: paymentMethodTypesService,
            tierLimitsProvider: tiersProviding
        )

        bankSectionInteractor = BanksSettingsSectionInteractor(
            paymentMethodTypesService: paymentMethodTypesService,
            tierLimitsProvider: tiersProviding
        )

        emailVerificationBadgeInteractor = EmailVerificationBadgeInteractor(
            service: settingsService
        )
        mobileVerificationBadgeInteractor = MobileVerificationBadgeInteractor(
            service: settingsService
        )
        twoFactorVerificationBadgeInteractor = TwoFactorVerificationBadgeInteractor(
            service: settingsService
        )
        preferredCurrencyBadgeInteractor = PreferredCurrencyBadgeInteractor(
            settingsService: settingsService,
            fiatCurrencyService: fiatCurrencyService
        )

        biometryProviding = BiometryProvider(settings: settingsAuthenticating, featureConfigurator: featureConfigurator)
        self.settingsAuthenticating = settingsAuthenticating
        pitConnnectionProviding = pitConnectionAPI
        recoveryPhraseStatusProviding = RecoveryPhraseStatusProvider(walletRecoveryVerifier: wallet)
        self.credentialsStore = credentialsStore
        self.authenticationCoordinator = authenticationCoordinator
    }

    func refresh() {
        recoveryPhraseStatusProviding.fetchTriggerRelay.accept(())
        pitConnnectionProviding.fetchTriggerRelay.accept(())
        tiersProviding.fetchTriggerRelay.accept(())
        settingsService.fetch(force: true)
            .subscribe()
            .disposed(by: disposeBag)
    }
}
