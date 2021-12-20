// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import FeatureSettingsDomain
import Foundation
import PlatformKit
import RxRelay
import RxSwift

final class PasswordRequiredScreenInteractor {

    // MARK: - Properties

    /// Streams potential parsing errors
    var error: Observable<Error> {
        errorRelay.asObservable()
    }

    /// Relay that accepts and streams the payload content
    let passwordRelay = BehaviorRelay<String>(value: "")

    private let walletPayloadService: WalletPayloadServiceAPI
    private let mobileAuthSyncService: MobileAuthSyncServiceAPI
    private let pushNotificationsRepository: PushNotificationsRepositoryAPI
    private let walletFetcher: (_ password: String) -> Void
    private let appSettings: BlockchainSettings.App
    private let walletManager: WalletManager
    private let credentialsStore: CredentialsStoreAPI

    // TODO: Consider the various of error types from the service layer,
    /// translate them into a interaction layer errors
    private let errorRelay = PublishRelay<Error>()

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    init(
        walletPayloadService: WalletPayloadServiceAPI = resolve(),
        mobileAuthSyncService: MobileAuthSyncServiceAPI = resolve(),
        pushNotificationsRepository: PushNotificationsRepositoryAPI = resolve(),
        walletManager: WalletManager = resolve(),
        appSettings: BlockchainSettings.App = resolve(),
        credentialsStore: CredentialsStoreAPI = resolve(),
        walletFetcher: @escaping ((_ password: String) -> Void)
    ) {
        self.walletPayloadService = walletPayloadService
        self.mobileAuthSyncService = mobileAuthSyncService
        self.pushNotificationsRepository = pushNotificationsRepository
        self.walletManager = walletManager
        self.walletFetcher = walletFetcher
        self.appSettings = appSettings
        self.credentialsStore = credentialsStore
    }

    /// Authenticates the wallet
    func authenticate() {
        walletPayloadService
            .requestUsingSharedKey()
            .asObservable()
            .ignoreElements()
            .subscribe(
                onError: errorRelay.accept,
                onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.walletFetcher(self.passwordRelay.value)
                }
            )
            .disposed(by: disposeBag)
    }

    /// Forgets the wallet
    func forget() {
        walletManager.forgetWallet()
        appSettings.clear()
        credentialsStore.erase()

        // TODO: [10/15/2021] Move this to CoreCoordinator with the forget wallet logic in the future
        Publishers.Zip3(
            // ignore failure
            pushNotificationsRepository.revokeToken().ignoreFailure(setFailureType: Error.self),
            mobileAuthSyncService.updateMobileSetup(isMobileSetup: false).ignoreFailure(),
            mobileAuthSyncService.verifyCloudBackup(hasCloudBackup: false).ignoreFailure()
        )
        .subscribe()
        .store(in: &cancellables)
    }
}
