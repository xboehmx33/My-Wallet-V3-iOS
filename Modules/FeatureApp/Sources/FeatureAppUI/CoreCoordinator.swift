// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import ComposableArchitecture
import DIKit
import ERC20Kit
import FeatureAppDomain
import FeatureAuthenticationDomain
import FeatureAuthenticationUI
import FeatureSettingsDomain
import Localization
import PlatformKit
import PlatformUIKit
import RemoteNotificationsKit
import ToolKit
import UIKit
import WalletPayloadKit

// swiftlint:disable file_length
/// Used for canceling publishers
private enum WalletCancelations {
    struct FetchId: Hashable {}
    struct DecryptId: Hashable {}
    struct AuthenticationId: Hashable {}
    struct InitializationId: Hashable {}
    struct UpgradeId: Hashable {}
    struct CreateId: Hashable {}
    struct RestoreId: Hashable {}
    struct RestoreFailedId: Hashable {}
    struct AssetInitializationId: Hashable {}
}

public struct CoreAppState: Equatable {
    public var onboarding: Onboarding.State? = .init()
    public var loggedIn: LoggedIn.State?
    public var deviceAuthorization: AuthorizeDeviceState?
    public var alertContent: AlertViewContent?

    var isLoggedIn: Bool {
        onboarding == nil && loggedIn != nil
    }

    public init(
        onboarding: Onboarding.State? = .init(),
        loggedIn: LoggedIn.State? = nil,
        deviceAuthorization: AuthorizeDeviceState? = nil
    ) {
        self.onboarding = onboarding
        self.loggedIn = loggedIn
        self.deviceAuthorization = deviceAuthorization
    }
}

public enum ProceedToLoggedInError: Error, Equatable {
    case coincore(CoincoreError)
    case erc20Service(ERC20CryptoAssetServiceError)
}

public enum CoreAppAction: Equatable {
    case start
    case loggedIn(LoggedIn.Action)
    case onboarding(Onboarding.Action)
    case prepareForLoggedIn
    case proceedToLoggedIn(Result<Bool, ProceedToLoggedInError>)
    case appForegrounded
    case deeplink(DeeplinkOutcome)
    case requirePin

    // Wallet Authentication
    case fetchWallet(password: String)
    case doFetchWallet(password: String)
    case authenticate
    case didDecryptWallet(WalletDecryption)
    case decryptionFailure(AuthenticationError)
    case authenticated(Result<Bool, AuthenticationError>)
    case setupPin
    case initializeWallet
    case walletInitialized
    case walletNeedsUpgrade(Bool)

    // Device Authorization
    case authorizeDevice(AuthorizeDeviceAction)
    case loginRequestReceived(deeplink: URL)
    case checkIfConfirmationRequired(sessionId: String, base64Str: String)
    case proceedToDeviceAuthorization(LoginRequestInfo)
    case deviceAuthorizationFinished

    // Wallet Creation
    case createWallet(email: String, newPassword: String)
    case create
    case created(Result<WalletCreation, WalletCreationError>)

    // Account Recovery
    case metadataRestoreWallet(seedPhrase: String)
    case importWallet(email: String, newPassword: String, seedPhrase: String)
    case restore
    case restored(Result<EmptyValue, WalletRecoveryError>)
    case resetPassword(newPassword: String)

    // Nabu Account Operations
    case resetVerificationStatusIfNeeded(guid: String?, sharedKey: String?)
    case recoverUser(guid: String, sharedKey: String, userId: String, recoveryToken: String)
    case setInitialResidentialAddress(country: String, state: String?)

    // Mobile Auth Sync
    case mobileAuthSync(isLogin: Bool)

    case none
}

struct CoreAppEnvironment {
    var loadingViewPresenter: LoadingViewPresenting
    var deeplinkHandler: DeepLinkHandling
    var deeplinkRouter: DeepLinkRouting
    var walletManager: WalletManagerAPI
    var mobileAuthSyncService: MobileAuthSyncServiceAPI
    var resetPasswordService: ResetPasswordServiceAPI
    var accountRecoveryService: AccountRecoveryServiceAPI
    var userService: NabuUserServiceAPI
    var deviceVerificationService: DeviceVerificationServiceAPI
    var featureFlagsService: FeatureFlagsServiceAPI
    var appFeatureConfigurator: FeatureConfiguratorAPI
    var fiatCurrencySettingsService: FiatCurrencySettingsServiceAPI
    var blockchainSettings: BlockchainSettingsAppAPI
    var credentialsStore: CredentialsStoreAPI
    var alertPresenter: AlertViewPresenterAPI
    var walletUpgradeService: WalletUpgradeServicing
    var exchangeRepository: ExchangeAccountRepositoryAPI
    var remoteNotificationServiceContainer: RemoteNotificationServiceContaining
    var coincore: CoincoreAPI
    var erc20CryptoAssetService: ERC20CryptoAssetServiceAPI
    var sharedContainer: SharedContainerUserDefaults
    var analyticsRecorder: AnalyticsEventRecorderAPI
    var siftService: FeatureAuthenticationDomain.SiftServiceAPI
    var onboardingSettings: OnboardingSettingsAPI
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var appStoreOpener: AppStoreOpening
    var walletService: WalletService
    var buildVersionProvider: () -> String
}

let mainAppReducer = Reducer<CoreAppState, CoreAppAction, CoreAppEnvironment>.combine(
    onBoardingReducer
        .optional()
        .pullback(
            state: \.onboarding,
            action: /CoreAppAction.onboarding,
            environment: { environment -> Onboarding.Environment in
                Onboarding.Environment(
                    appSettings: environment.blockchainSettings,
                    alertPresenter: environment.alertPresenter,
                    mainQueue: environment.mainQueue,
                    deviceVerificationService: environment.deviceVerificationService,
                    featureFlagsService: environment.featureFlagsService,
                    buildVersionProvider: environment.buildVersionProvider
                )
            }
        ),
    loggedInReducer
        .optional()
        .pullback(
            state: \.loggedIn,
            action: /CoreAppAction.loggedIn,
            environment: { environment -> LoggedIn.Environment in
                LoggedIn.Environment(
                    mainQueue: environment.mainQueue,
                    analyticsRecorder: environment.analyticsRecorder,
                    loadingViewPresenter: environment.loadingViewPresenter,
                    exchangeRepository: environment.exchangeRepository,
                    remoteNotificationTokenSender: environment.remoteNotificationServiceContainer.tokenSender,
                    remoteNotificationAuthorizer: environment.remoteNotificationServiceContainer.authorizer,
                    walletManager: environment.walletManager,
                    appSettings: environment.blockchainSettings,
                    deeplinkRouter: environment.deeplinkRouter,
                    featureFlagsService: environment.featureFlagsService,
                    fiatCurrencySettingsService: environment.fiatCurrencySettingsService
                )
            }
        ),
    authorizeDeviceReducer
        .optional()
        .pullback(
            state: \.deviceAuthorization,
            action: /CoreAppAction.authorizeDevice,
            environment: {
                AuthorizeDeviceEnvironment(
                    mainQueue: $0.mainQueue,
                    deviceVerificationService: $0.deviceVerificationService
                )
            }
        ),
    mainAppReducerCore
)

// swiftlint:disable closure_body_length
let mainAppReducerCore = Reducer<CoreAppState, CoreAppAction, CoreAppEnvironment> { state, action, environment in
    switch action {
    case .start:
        return .merge(
            .fireAndForget {
                environment.appFeatureConfigurator.initialize()
            },
            .fireAndForget {
                syncPinKeyWithICloud(
                    blockchainSettings: environment.blockchainSettings,
                    credentialsStore: environment.credentialsStore
                )
            }
        )

    case .appForegrounded:
        // check if we need to display the pin for authentication
        guard environment.walletManager.walletIsInitialized() else {
            // do nothing if we're on the authentication state,
            // meaning we either need to register, login or recover
            guard state.isLoggedIn else {
                return .none
            }
            // We need to send the `stop` action prior we show the pin entry,
            // this clears any running operation from the logged-in state.
            return .concatenate(
                Effect(value: .loggedIn(.stop)),
                Effect(value: .requirePin)
            )
        }
        return .none

    case .deeplink(.handleLink(let content)) where content.context == .dynamicLinks:
        // for context this performs side-effect to values in the appSettings
        // it'll then be up to the `DeeplinkRouter` to capture any of these changes
        // and route if needed, the router is handled once we're in a logged-in state
        environment.deeplinkHandler.handle(deepLink: content.url.absoluteString)
        return .none

    case .deeplink(.handleLink(let content)) where content.context.usableOnlyDuringAuthentication:
        // currently we only support only one deeplink for login, so being naive here
        guard content.context == .blockchainLinks(.login) else {
            return .none
        }
        // handle deeplink if we've entered verify device flow
        if let onboarding = state.onboarding,
           let authState = onboarding.welcomeState,
           let loginState = authState.emailLoginState,
           loginState.verifyDeviceState != nil
        {
            // Pass content to welcomeScreen to be handled
            return Effect(value: .onboarding(.welcomeScreen(.deeplinkReceived(content.url))))
        } else {
            return Effect(value: .loginRequestReceived(deeplink: content.url))
        }

    case .deeplink(.handleLink(let content)):
        // we first check if we're logged in, if not we need to defer the deeplink routing
        guard state.isLoggedIn else {
            // continue if we're on the onboarding state
            guard let onboarding = state.onboarding else {
                return .none
            }
            // check if we're on the pinState and we need the user to enter their pin
            if let pinState = onboarding.pinState,
               pinState.requiresPinAuthentication,
               !content.context.usableOnlyDuringAuthentication
            {
                // defer the deeplink until we handle the `.proceedToLoggedIn` action
                state.onboarding?.deeplinkContent = content
            }
            return .none
        }
        // continue with the deeplink
        return Effect(value: .loggedIn(.deeplink(content)))

    case .deeplink(.informAppNeedsUpdate):
        // TODO: This is ugly, rethink how we handle alert actions
        let actions = [
            UIAlertAction(
                title: LocalizationConstants.DeepLink.updateNow,
                style: .default,
                handler: { [environment] _ in
                    environment.appStoreOpener.openAppStore()
                }
            ),
            UIAlertAction(title: LocalizationConstants.cancel, style: .cancel)
        ]
        state.alertContent = AlertViewContent(
            title: LocalizationConstants.DeepLink.deepLinkUpdateTitle,
            message: LocalizationConstants.DeepLink.deepLinkUpdateMessage,
            actions: actions
        )
        return .none

    case .deeplink(.ignore):
        return .none

    case .requirePin:
        state.loggedIn = nil
        state.onboarding = .init()
        return Effect(value: .onboarding(.start))

    case .fetchWallet(let password):
        environment.loadingViewPresenter.showCircular()
        return nativeWalletFlagEnabled()
            .flatMap { nativeWalletEnabled -> Effect<CoreAppAction, Never> in
                guard nativeWalletEnabled else {
                    // As much as I (Dimitris) hate delay-ing work this is one of those method
                    // that I'm going to make an exception, mainly because it's going to be replaced soon.
                    // This is to give a change for the circular loader to appear before
                    // we call `fetch(with: _password_)` which will call the evil that is JS.
                    return .merge(
                        Effect(value: .doFetchWallet(password: password))
                            .delay(for: .milliseconds(200), scheduler: environment.mainQueue)
                            .eraseToEffect()
                            .cancellable(id: WalletCancelations.FetchId(), cancelInFlight: true),
                        Effect(value: .authenticate)
                    )
                }
                return Effect(value: .doFetchWallet(password: password))
            }
            .eraseToEffect()

    case .doFetchWallet(let password):
        let walletManager = environment.walletManager
        let walletService = environment.walletService
        let mainQueue = environment.mainQueue
        return nativeWalletFlagEnabled()
            .flatMap { nativeWalletEnabled -> Effect<CoreAppAction, Never> in
                guard nativeWalletEnabled else {
                    walletManager.fetch(with: password)
                    return .cancel(id: WalletCancelations.FetchId())
                }
                // Runs the native wallet fetching
                return walletService.fetch(password)
                    .receive(on: mainQueue)
                    .catchToEffect()
                    .cancellable(id: WalletCancelations.FetchId(), cancelInFlight: true)
                    .map { _ in CoreAppAction.walletInitialized }
            }
            .eraseToEffect()

    case .authenticate:
        return .merge(
            environment.walletManager.didDecryptWallet
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .cancellable(id: WalletCancelations.DecryptId(), cancelInFlight: false)
                .map { result -> CoreAppAction in
                    guard case .success(let value) = result else {
                        return .none
                    }
                    return handleWalletDecryption(value)
                },
            environment.walletManager.didCompleteAuthentication
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .cancellable(id: WalletCancelations.AuthenticationId(), cancelInFlight: false)
                .map { result -> CoreAppAction in
                    guard case .success(let value) = result else {
                        return CoreAppAction.authenticated(
                            .failure(.init(code: AuthenticationError.ErrorCode.unknown))
                        )
                    }
                    return CoreAppAction.authenticated(value)
                }
        )

    case .didDecryptWallet(let decryption):
        // defer showing the loading spinner, we should find a better way of dealing with this
        // for context the underlying implementation of showing the circular loader
        // relies on attaching the loader to the top window's view!!, this is error-prone and there are cases
        // where the loader would not show above a presented view controller...
        environment.loadingViewPresenter.hide()

        // skip saving guid and sharedKey if we detect a second password is needed
        // TODO: Refactor this so that we don't call legacy methods directly
        if environment.walletManager.walletNeedsSecondPassword(),
           state.onboarding?.welcomeState != nil
        {
            return .cancel(id: WalletCancelations.DecryptId())
        }

        environment.loadingViewPresenter.showCircular()
        environment.blockchainSettings.guid = decryption.guid
        environment.blockchainSettings.sharedKey = decryption.sharedKey

        return .merge(
            // reset KYC verification if decrypted wallet under recovery context
            Effect(value: .resetVerificationStatusIfNeeded(
                guid: decryption.guid,
                sharedKey: decryption.sharedKey
            )),
            .cancel(id: WalletCancelations.DecryptId()),
            .fireAndForget {
                clearPinIfNeeded(
                    for: decryption.passwordPartHash,
                    appSettings: environment.blockchainSettings
                )
            }
        )

    case .decryptionFailure(let error):
        state.onboarding?.displayAlert = .walletAuthentication(error)
        return .cancel(id: WalletCancelations.DecryptId())

    case .authenticated(.failure(let error)) where error.code == .failedToLoadWallet:
        guard state.onboarding?.welcomeState != nil else {
            state.onboarding?.displayAlert = .walletAuthentication(error)
            return .cancel(id: WalletCancelations.AuthenticationId())
        }
        if state.onboarding?.welcomeState?.manualCredentialsState != nil {
            return .merge(
                .cancel(id: WalletCancelations.AuthenticationId()),
                Effect(
                    value: CoreAppAction.onboarding(
                        .welcomeScreen(
                            .manualPairing(
                                .password(
                                    .showIncorrectPasswordError(true)
                                )
                            )
                        )
                    )
                )
            )
        }
        return .merge(
            .cancel(id: WalletCancelations.AuthenticationId()),
            Effect(
                value: CoreAppAction.onboarding(
                    .welcomeScreen(
                        .emailLogin(
                            .verifyDevice(
                                .credentials(
                                    .password(
                                        .showIncorrectPasswordError(true)
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )

    case .authenticated(.failure(let error)):
        state.onboarding?.displayAlert = .walletAuthentication(error)
        return .cancel(id: WalletCancelations.AuthenticationId())

    case .authenticated(.success):
        // when on authenticated success we need to check if the wallet
        // requires a second password, if we do then we stop the process
        // and display a notice to the user
        // TODO: Refactor this so that we don't call legacy methods directly
        if environment.walletManager.walletNeedsSecondPassword(),
           state.onboarding?.welcomeState != nil
        {
            // unfortunately during login we store the guid in the settings
            // we need to reset this if we detect a second password
            environment.blockchainSettings.guid = nil
            environment.blockchainSettings.sharedKey = nil
            return .merge(
                .cancel(id: WalletCancelations.AuthenticationId()),
                Effect(
                    value: .onboarding(.informSecondPasswordDetected)
                )
            )
        }
        // decide if we need to reset password or not (we need to reset password after metadata recovery)
        // if needed, go to reset password screen, if not, go to PIN screen
        if let context = state.onboarding?.walletRecoveryContext,
           context == .metadataRecovery
        {
            environment.loadingViewPresenter.hide()
            // if it is from the restore wallet screen
            if state.onboarding?.welcomeState?.restoreWalletState != nil {
                return .merge(
                    .cancel(id: WalletCancelations.AuthenticationId()),
                    Effect(value: .onboarding(.welcomeScreen(.restoreWallet(.setResetPasswordScreenVisible(true)))))
                )
                // if it is from the trouble logging in screen
            } else if state.onboarding?.welcomeState?.emailLoginState != nil {
                return .merge(
                    .cancel(id: WalletCancelations.AuthenticationId()),
                    Effect(value:
                        .onboarding(
                            .welcomeScreen(.emailLogin(.verifyDevice(.credentials(.seedPhrase(.setResetPasswordScreenVisible(true))))))
                        )
                    )
                )
            }
        }
        // decide if we need to set a pin or not
        guard environment.blockchainSettings.isPinSet else {
            guard state.onboarding?.welcomeState != nil else {
                return .merge(
                    .cancel(id: WalletCancelations.AuthenticationId()),
                    Effect(value: .setupPin)
                )
            }
            return .merge(
                .cancel(id: WalletCancelations.AuthenticationId()),
                Effect(value: .onboarding(.welcomeScreen(.dismiss()))),
                Effect(value: .setupPin)
            )
        }
        return .merge(
            .cancel(id: WalletCancelations.AuthenticationId()),
            Effect(value: .initializeWallet)
        )

    case .setupPin:
        environment.loadingViewPresenter.hide()
        state.onboarding?.pinState = .init()
        state.onboarding?.passwordScreen = nil
        return Effect(value: CoreAppAction.onboarding(.pin(.create)))

    case .initializeWallet:
        return environment.walletManager
            .reactiveWallet
            .waitUntilInitializedSinglePublisher
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .cancellable(id: WalletCancelations.InitializationId(), cancelInFlight: false)
            .map { _ in CoreAppAction.walletInitialized }

    case .walletInitialized:
        return environment.walletUpgradeService
            .needsWalletUpgradePublisher
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .cancellable(id: WalletCancelations.UpgradeId(), cancelInFlight: false)
            .map { result -> CoreAppAction in
                guard case .success(let shouldUpgrade) = result else {
                    // impossible with current `WalletUpgradeServicing` implementation
                    return CoreAppAction.prepareForLoggedIn
                }
                return CoreAppAction.walletNeedsUpgrade(shouldUpgrade)
            }

    case .walletNeedsUpgrade(let shouldUpgrade):
        // check if we need the wallet needs an upgrade otherwise proceed to logged in state
        guard shouldUpgrade else {
            return Effect(value: CoreAppAction.prepareForLoggedIn)
        }
        environment.loadingViewPresenter.hide()
        state.onboarding?.pinState = nil
        state.onboarding?.walletUpgradeState = WalletUpgrade.State()
        return .merge(
            .cancel(id: WalletCancelations.InitializationId()),
            .cancel(id: WalletCancelations.UpgradeId()),
            Effect(value: CoreAppAction.onboarding(.walletUpgrade(.begin)))
        )

    case .loginRequestReceived(let deeplink):
        return environment
            .featureFlagsService
            .isEnabled(.remote(.pollingForEmailLogin))
            .flatMap { isEnabled -> Effect<CoreAppAction, Never> in
                guard isEnabled else {
                    return .none
                }
                return environment
                    .deviceVerificationService
                    .handleLoginRequestDeeplink(url: deeplink)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map { result -> CoreAppAction in
                        guard case .failure(let error) = result else {
                            // if success, just ignore the effect
                            return .none
                        }
                        switch error {
                        // when catched a deeplink with a different session token,
                        // or when there is no session token from the app,
                        // it means a login magic link generated from a different device is catched
                        // proceed to login request authorization in this case
                        case .missingSessionToken(let sessionId, let base64Str),
                             .sessionTokenMismatch(let sessionId, let base64Str):
                            return .checkIfConfirmationRequired(sessionId: sessionId, base64Str: base64Str)
                        case .failToDecodeBase64Component,
                             .failToDecodeToWalletInfo:
                            return .none
                        }
                    }
            }
            .eraseToEffect()

    case .onboarding(.welcomeScreen(.emailLogin(.verifyDevice(.checkIfConfirmationRequired(let sessionId, let base64Str))))),
         .checkIfConfirmationRequired(let sessionId, let base64Str):
        return environment
            .deviceVerificationService
            // trigger confirmation required error
            .authorizeVerifyDevice(from: sessionId, payload: base64Str, confirmDevice: nil)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map { result -> CoreAppAction in
                guard case .failure(let error) = result else {
                    return .none
                }
                switch error {
                case .confirmationRequired(let timestamp, let details):
                    let info = LoginRequestInfo(
                        sessionId: sessionId,
                        base64Str: base64Str,
                        details: details,
                        timestamp: timestamp
                    )
                    return .proceedToDeviceAuthorization(info)
                default:
                    return .none
                }
            }

    case .proceedToDeviceAuthorization(let loginRequestInfo):
        state.deviceAuthorization = .init(
            loginRequestInfo: loginRequestInfo
        )
        return .none

    case .deviceAuthorizationFinished:
        state.deviceAuthorization = nil
        return .none

    case .createWallet(let email, let password):
        let createState = state.onboarding?.welcomeState?.createWalletState
        func setInitialAddressEffect() -> Effect<CoreAppAction, Never> {
            guard let createState = createState else {
                return .none
            }
            let country = createState.country.id.description
            let state = createState.countryState?.id.description
            return Effect(value: .setInitialResidentialAddress(country: country, state: state))
        }

        environment.loadingViewPresenter.showCircular()
        environment.walletManager.loadWalletJS()
        environment.walletManager.newWallet(password: password, email: email)

        // Setting country and state requires us to have an authenticated user, so:
        return .concatenate(
            // Step 1: create a wallet and authenticate the user to ensure we have an authenticated user
            .merge(
                Effect(value: .create),
                Effect(value: .authenticate)
            ),
            // Step 2: update the user info with country and state
            setInitialAddressEffect()
        )

    case .create:
        return environment
            .walletManager
            .didCreateNewAccount
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .cancellable(id: WalletCancelations.CreateId(), cancelInFlight: false)
            .map { result -> CoreAppAction in
                guard case .success(let value) = result else {
                    return .created(
                        .failure(.unknownError("Unknown Wallet Creation Error"))
                    )
                }
                return .created(value)
            }

    case .created(.failure(let error)):
        state.onboarding?.displayAlert = .walletCreation(error)
        return .cancel(id: WalletCancelations.CreateId())

    case .created(.success(let walletCreation)):
        environment.walletManager.forgetWallet()
        environment.walletManager.load(
            with: walletCreation.guid,
            sharedKey: walletCreation.sharedKey,
            password: walletCreation.password
        )
        environment.walletManager.markWalletAsNew()
        BlockchainSettings.App.shared.hasEndedFirstSession = false

        // created wallet through reset account recovery
        if let nabuInfo = state.onboarding?.nabuInfoForResetAccount {
            return .merge(
                .cancel(id: WalletCancelations.CreateId()),
                Effect(
                    value: .recoverUser(
                        guid: walletCreation.guid,
                        sharedKey: walletCreation.sharedKey,
                        userId: nabuInfo.userId,
                        recoveryToken: nabuInfo.recoveryToken
                    )
                )
            )
        } else {
            return .merge(
                .cancel(id: WalletCancelations.CreateId()),
                Effect(value: .authenticate)
            )
        }

    case .metadataRestoreWallet(let seedPhrase):
        environment.loadingViewPresenter.showCircular()
        environment.walletManager.loadWalletJS()
        environment.walletManager.recoverFromMetadata(
            seedPhrase: seedPhrase
        )
        state.onboarding?.walletRecoveryContext = .metadataRecovery
        return .merge(
            Effect(value: .restore),
            Effect(value: .authenticate)
        )

    case .importWallet(let email, let password, let seedPhrase):
        environment.loadingViewPresenter.showCircular()
        environment.walletManager.loadWalletJS()
        environment.walletManager.recover(
            email: email,
            password: password,
            seedPhrase: seedPhrase
        )
        state.onboarding?.walletRecoveryContext = .importRecovery
        return .merge(
            Effect(value: .restore),
            Effect(value: .authenticate)
        )

    case .restore:
        return .merge(
            environment
                .walletManager
                .walletRecovered
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .cancellable(id: WalletCancelations.RestoreId(), cancelInFlight: false)
                .map { result -> CoreAppAction in
                    guard case .success = result else {
                        return .restored(.failure(.failedToRestoreWallet))
                    }
                    return .restored(.success(.noValue))
                },
            environment
                .walletManager
                .walletRecoveryFailed
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .cancellable(id: WalletCancelations.RestoreFailedId(), cancelInFlight: false)
                .map { result -> CoreAppAction in
                    guard case .success = result else {
                        return .none
                    }
                    return .restored(.failure(.failedToRestoreWallet))
                }
        )

    case .restored(.success):
        return .merge(
            .cancel(id: WalletCancelations.RestoreId()),
            .cancel(id: WalletCancelations.RestoreFailedId())
        )

    case .restored(.failure):
        guard let recoveryContext = state.onboarding?.walletRecoveryContext,
              recoveryContext == .metadataRecovery
        else {
            state.onboarding?.displayAlert = .walletRecovery(.failedToRestoreWallet)
            return .merge(
                .cancel(id: WalletCancelations.RestoreId()),
                .cancel(id: WalletCancelations.RestoreFailedId())
            )
        }
        if state.onboarding?.welcomeState?.restoreWalletState != nil {
            return .merge(
                Effect(value: .onboarding(.welcomeScreen(.restoreWallet(.setImportWalletScreenVisible(true))))),
                .cancel(id: WalletCancelations.RestoreId()),
                .cancel(id: WalletCancelations.RestoreFailedId())
            )
        } else if state.onboarding?.welcomeState?.emailLoginState != nil {
            return .merge(
                Effect(value: .onboarding(.welcomeScreen(.emailLogin(
                    .verifyDevice(.credentials(.seedPhrase(
                        .setImportWalletScreenVisible(true)
                    )))
                )))),
                .cancel(id: WalletCancelations.RestoreId()),
                .cancel(id: WalletCancelations.RestoreFailedId())
            )
        }
        return .merge(
            .cancel(id: WalletCancelations.RestoreId()),
            .cancel(id: WalletCancelations.RestoreFailedId())
        )

    case .prepareForLoggedIn:
        let coincoreInit = environment.coincore
            .initialize()
            .mapError(ProceedToLoggedInError.coincore)
        let erc20Init = environment.erc20CryptoAssetService
            .initialize()
            .mapError(ProceedToLoggedInError.erc20Service)
            .eraseToAnyPublisher()

        return coincoreInit
            .flatMap { _ in
                erc20Init
            }
            .receive(on: environment.mainQueue)
            .catchToEffect { result in
                switch result {
                case .failure(let error):
                    return .failure(error)
                case .success:
                    return .success(true)
                }
            }
            .cancellable(id: WalletCancelations.AssetInitializationId(), cancelInFlight: false)
            .map(CoreAppAction.proceedToLoggedIn)

    case .proceedToLoggedIn(.failure(let error)):
        state.onboarding?.displayAlert = .proceedToLoggedIn(error)
        return .merge(
            .cancel(id: WalletCancelations.AssetInitializationId()),
            .cancel(id: WalletCancelations.InitializationId()),
            .cancel(id: WalletCancelations.UpgradeId())
        )

    case .proceedToLoggedIn(.success):
        environment.loadingViewPresenter.hide()
        // prepare the context for logged in state, if required
        var context: LoggedIn.Context = .none
        if let deeplinkContent = state.onboarding?.deeplinkContent {
            context = .deeplink(deeplinkContent)
        }
        if let walletContext = state.onboarding?.walletCreationContext {
            context = .wallet(walletContext)
        }
        state.loggedIn = LoggedIn.State()
        state.onboarding = nil
        return .merge(
            .fireAndForget {
                environment.analyticsRecorder.record(
                    event: AnalyticsEvents.New.Navigation.signedIn
                )
            },
            .cancel(id: WalletCancelations.AssetInitializationId()),
            .cancel(id: WalletCancelations.InitializationId()),
            .cancel(id: WalletCancelations.UpgradeId()),
            Effect(value: CoreAppAction.loggedIn(.start(context))),
            Effect(value: CoreAppAction.mobileAuthSync(isLogin: true))
        )

    case .onboarding(.welcomeScreen(.emailLogin(.verifyDevice(.credentials(.seedPhrase(.resetPassword(.reset(let password)))))))),
         .onboarding(.welcomeScreen(.restoreWallet(.resetPassword(.reset(let password))))):
        return Effect(value: .resetPassword(newPassword: password))

    case .onboarding(.createAccountScreenClosed):
        // cancel any authentication publishers in case the create wallet is closed
        environment.loadingViewPresenter.hide()
        return .merge(
            .cancel(id: WalletCancelations.DecryptId()),
            .cancel(id: WalletCancelations.AuthenticationId())
        )

    case .onboarding(.walletUpgrade(.completed)):
        return Effect(
            value: CoreAppAction.prepareForLoggedIn
        )

    case .onboarding(.passwordScreen(.authenticate(let password))):
        return Effect(
            value: .fetchWallet(password: password)
        )

    case .onboarding(.pin(.handleAuthentication(let password))):
        return Effect(
            value: .fetchWallet(password: password)
        )

    case .onboarding(.pin(.pinCreated)):
        return Effect(
            value: .initializeWallet
        )

    case .onboarding(.welcomeScreen(.requestedToCreateWallet(let email, let password))):
        return Effect(
            value: .createWallet(email: email, newPassword: password)
        )

    case .onboarding(.welcomeScreen(.requestedToDecryptWallet(let password))):
        return Effect(
            value: .fetchWallet(password: password)
        )

    case .onboarding(.welcomeScreen(.requestedToRestoreWallet(let walletRecovery))):
        switch walletRecovery {
        case .metadataRecovery(let seedPhrase):
            return Effect(
                value: .metadataRestoreWallet(seedPhrase: seedPhrase)
            )
        case .importRecovery(let email, let newPassword, let seedPhrase):
            return Effect(
                value: .importWallet(
                    email: email,
                    newPassword: newPassword,
                    seedPhrase: seedPhrase
                )
            )
        case .resetAccountRecovery(let email, let newPassword, let nabuInfo):
            state.onboarding?.nabuInfoForResetAccount = nabuInfo
            return Effect(
                value: .createWallet(
                    email: email,
                    newPassword: newPassword
                )
            )
        }

    case .onboarding(.pin(.logout)),
         .loggedIn(.logout):
        // reset
        environment.walletManager.close()

        NotificationCenter.default.post(name: .logout, object: nil)
        environment.analyticsRecorder.record(
            event: AnalyticsEvents.New.Navigation.signedOut
        )

        environment.siftService.removeUserId()
        environment.sharedContainer.reset()
        environment.blockchainSettings.reset()
        environment.onboardingSettings.reset()

        // update state
        state.loggedIn = nil
        state.onboarding = .init(pinState: nil, walletUpgradeState: nil, passwordScreen: .init())
        // show password screen
        return Effect(value: .onboarding(.passwordScreen(.start)))

    case .loggedIn(.wallet(.authenticateForBiometrics(let password))):
        return Effect(value: .fetchWallet(password: password))

    case .resetPassword(let newPassword):
        return environment
            .resetPasswordService
            .setNewPassword(newPassword: newPassword)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map { result -> CoreAppAction in
                guard case .success = result else {
                    environment.analyticsRecorder.record(
                        event: AnalyticsEvents.New.AccountRecoveryCoreFlow.accountRecoveryFailed
                    )
                    return .none
                }
                environment.analyticsRecorder.record(
                    event: AnalyticsEvents.New.AccountRecoveryCoreFlow
                        .accountPasswordReset(hasRecoveryPhrase: true)
                )
                // proceed to setup PIN after reset password if needed
                guard environment.blockchainSettings.isPinSet else {
                    return .setupPin
                }
                return .none
            }

    case .resetVerificationStatusIfNeeded(let guidOrNil, let sharedKeyOrNil):
        guard let context = state.onboarding?.walletRecoveryContext,
              let guid = guidOrNil,
              let sharedKey = sharedKeyOrNil
        else {
            return .none
        }
        return environment
            .accountRecoveryService
            .resetVerificationStatus(guid: guid, sharedKey: sharedKey)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map { result -> CoreAppAction in
                guard case .success = result else {
                    environment.analyticsRecorder.record(
                        event: AnalyticsEvents.New.AccountRecoveryCoreFlow.accountRecoveryFailed
                    )
                    return .none
                }
                return .none
            }

    case .recoverUser(let guid, let sharedKey, let userId, let recoveryToken):
        return environment
            .accountRecoveryService
            .recoverUser(
                guid: guid,
                sharedKey: sharedKey,
                userId: userId,
                recoveryToken: recoveryToken
            )
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map { result -> CoreAppAction in
                guard case .success = result else {
                    environment.analyticsRecorder.record(
                        event: AnalyticsEvents.New.AccountRecoveryCoreFlow.accountRecoveryFailed
                    )
                    // show recovery failures if the endpoint fails
                    return .onboarding(
                        .welcomeScreen(
                            .emailLogin(
                                .verifyDevice(
                                    .credentials(
                                        .seedPhrase(
                                            .lostFundsWarning(
                                                .resetPassword(.setResetAccountFailureVisible(true))
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                }
                environment.analyticsRecorder.record(
                    event: AnalyticsEvents.New.AccountRecoveryCoreFlow
                        .accountPasswordReset(hasRecoveryPhrase: false)
                )
                return .none
            }

    case .setInitialResidentialAddress(let country, let state):
        // I wanted to use `.fireAndForget` for this, but the call returns a `Publisher`, so it makes sense to convert it to an `Effect`.
        // Otherwise, we'd have to sink and store the cancellable in a set we don't have here, nor want to have.
        return environment.userService.setInitialResidentialInfo(
            country: country,
            state: state
        )
        // we don't care about the result, we have nothing to do with it here
        .map(CoreAppAction.none)
        // we also don't care about failures as users will be asked about country and state during KYC if we don't have that info yet
        .ignoreFailure()
        .receive(on: environment.mainQueue)
        .eraseToEffect()

    case .mobileAuthSync(let isLogin):
        return .merge(
            environment
                .mobileAuthSyncService
                .updateMobileSetup(isMobileSetup: isLogin)
                .receive(on: environment.mainQueue)
                .eraseToEffect()
                .fireAndForget(),
            environment
                .mobileAuthSyncService
                .verifyCloudBackup(hasCloudBackup: isLogin)
                .receive(on: environment.mainQueue)
                .eraseToEffect()
                .fireAndForget()
        )

    case .onboarding,
         .loggedIn,
         .authorizeDevice,
         .none:
        return .none
    }
}

// MARK: Private Methods

/// - Note:
/// In order to login to wallet, we need to know:
/// - GUID                 - To look up the wallet
/// - SharedKey            - To be able to read/write to the wallet db record (payload, settings, etc)
/// - EncryptedPinPassword - To decrypt the wallet
/// - PinKey               - Used in conjunction with the user's PIN to retrieve decryption key to the -  EncryptedPinPassword (EncryptedWalletPassword)
/// - PIN                  - Provided by the user or retrieved from secure enclave if Face/TouchID is enabled
///
/// In this method, we backup/restore the pinKey - which is essentially the identifier of the PIN.
/// Upon successful PIN authentication, we will backup/restore the remaining wallet details: guid, sharedKey, encryptedPinPassword.
///
/// The backup/restore of guid and sharedKey requires an encryption/decryption step when backing up and restoring respectively.
///
/// The key used to encrypt/decrypt the guid and sharedKey is provided in the response to a successful PIN auth attempt.
internal func syncPinKeyWithICloud(
    blockchainSettings: BlockchainSettingsAppAPI,
    credentialsStore: CredentialsStoreAPI
) {
    guard !blockchainSettings.isPairedWithWallet else {
        // Wallet is Paired, we do not need to restore.
        // We will back up after pin authentication
        return
    }

    if blockchainSettings.pinKey == nil,
       blockchainSettings.encryptedPinPassword == nil,
       blockchainSettings.guid == nil,
       blockchainSettings.sharedKey == nil
    {

        credentialsStore.synchronize()

        // Attempt to restore the pinKey from iCloud
        if let pinData = credentialsStore.pinData() {
            blockchainSettings.pinKey = pinData.pinKey
            blockchainSettings.encryptedPinPassword = pinData.encryptedPinPassword
        }
    }
}

func handleWalletDecryption(_ decryption: WalletDecryption) -> CoreAppAction {

    //// Verify valid GUID and sharedKey
    guard let guid = decryption.guid, guid.count == 36 else {
        return .decryptionFailure(
            AuthenticationError(
                code: AuthenticationError.ErrorCode.errorDecryptingWallet,
                description: LocalizationConstants.Authentication.errorDecryptingWallet
            )
        )
    }

    guard let sharedKey = decryption.sharedKey, sharedKey.count == 36 else {
        return .decryptionFailure(
            AuthenticationError(
                code: AuthenticationError.ErrorCode.invalidSharedKey,
                description: LocalizationConstants.Authentication.invalidSharedKey
            )
        )
    }

    return .didDecryptWallet(decryption)
}

func clearPinIfNeeded(for passwordPartHash: String?, appSettings: AppSettingsAuthenticating) {
    // Because we are not storing the password on the device. We record the first few letters of the hashed password.
    // With the hash prefix we can then figure out if the password changed. If so, clear the pin
    // so that the user can reset it
    guard let passwordPartHash = passwordPartHash,
          let savedPasswordPartHash = appSettings.passwordPartHash
    else {
        return
    }

    guard passwordPartHash != savedPasswordPartHash else {
        return
    }

    appSettings.clearPin()
}
