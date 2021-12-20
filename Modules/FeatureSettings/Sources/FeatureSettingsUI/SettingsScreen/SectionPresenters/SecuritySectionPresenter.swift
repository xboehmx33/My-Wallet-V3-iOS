// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import RxSwift

final class SecuritySectionPresenter: SettingsSectionPresenting {
    let sectionType: SettingsSectionType = .security

    var state: Observable<SettingsSectionLoadingState> {
        .just(
            .loaded(next:
                .some(
                    .init(
                        sectionType: sectionType,
                        items: [
                            .init(cellType: .switch(.sms2FA, smsTwoFactorSwitchCellPresenter)),
                            .init(cellType: .switch(.cloudBackup, cloudBackupSwitchCellPresenter)),
                            .init(cellType: .common(.changePassword)),
                            .init(cellType: .badge(.recoveryPhrase, recoveryCellPresenter)),
                            .init(cellType: .common(.changePIN)),
                            .init(cellType: .switch(.bioAuthentication, bioAuthenticationCellPresenter)),
                            .init(cellType: .switch(.balanceSyncing, balanceSyncingCellPresenter)),
                            .init(cellType: .common(.addresses))
                        ]
                    )
                )
            )
        )
    }

    private let recoveryCellPresenter: RecoveryStatusCellPresenter
    private let bioAuthenticationCellPresenter: BioAuthenticationSwitchCellPresenter
    private let smsTwoFactorSwitchCellPresenter: SMSTwoFactorSwitchCellPresenter
    private let balanceSyncingCellPresenter: BalanceSharingSwitchCellPresenter
    private let cloudBackupSwitchCellPresenter: CloudBackupSwitchCellPresenter

    init(
        smsTwoFactorService: SMSTwoFactorSettingsServiceAPI,
        credentialsStore: CredentialsStoreAPI,
        biometryProvider: BiometryProviding,
        settingsAuthenticater: AppSettingsAuthenticating,
        recoveryPhraseStatusProvider: RecoveryPhraseStatusProviding,
        balanceSharingService: BalanceSharingSettingsServiceAPI,
        authenticationCoordinator: AuthenticationCoordinating,
        appSettings: BlockchainSettings.App = resolve()
    ) {
        smsTwoFactorSwitchCellPresenter = SMSTwoFactorSwitchCellPresenter(
            service: smsTwoFactorService
        )
        bioAuthenticationCellPresenter = BioAuthenticationSwitchCellPresenter(
            biometryProviding: biometryProvider,
            appSettingsAuthenticating: settingsAuthenticater,
            authenticationCoordinator: authenticationCoordinator
        )
        recoveryCellPresenter = RecoveryStatusCellPresenter(
            recoveryStatusProviding: recoveryPhraseStatusProvider
        )
        balanceSyncingCellPresenter = BalanceSharingSwitchCellPresenter(
            service: balanceSharingService
        )
        cloudBackupSwitchCellPresenter = CloudBackupSwitchCellPresenter(
            appSettings: appSettings,
            credentialsStore: credentialsStore
        )
    }
}
