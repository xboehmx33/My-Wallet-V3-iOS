// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import DIKit
import FeatureOpenBankingDomain
import FeatureSettingsDomain
import ToolKit
import WalletPayloadKit

enum AppCancellations {
    struct DeeplinkId: Hashable {}
    struct WalletPersistenceId: Hashable {}
}

public struct AppState: Equatable {
    public var appSettings: AppDelegateState = .init()
    public var coreState: CoreAppState = .init()

    public init(
        appSettings: AppDelegateState = .init(),
        coreState: CoreAppState = .init()
    ) {
        self.appSettings = appSettings
        self.coreState = coreState
    }
}

public enum AppAction: Equatable {
    case appDelegate(AppDelegateAction)
    case core(CoreAppAction)
    case walletPersistence(WalletPersistenceAction)
    case none
}

public enum WalletPersistenceAction: Equatable {
    case begin
    case cancel
    case persisted(Result<EmptyValue, WalletRepoPersistenceError>)
}

public let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    appDelegateReducer
        .pullback(
            state: \.appSettings,
            action: /AppAction.appDelegate,
            environment: {
                AppDelegateEnvironment(
                    appSettings: $0.blockchainSettings,
                    onboardingSettings: $0.onboardingSettings,
                    cacheSuite: $0.cacheSuite,
                    remoteNotificationBackgroundReceiver: $0.remoteNotificationServiceContainer.backgroundReceiver,
                    remoteNotificationAuthorizer: $0.remoteNotificationServiceContainer.authorizer,
                    remoteNotificationTokenReceiver: $0.remoteNotificationServiceContainer.tokenReceiver,
                    certificatePinner: $0.certificatePinner,
                    siftService: $0.siftService,
                    customerSupportChatService: $0.customerSupportChatService,
                    blurEffectHandler: $0.blurEffectHandler,
                    backgroundAppHandler: $0.backgroundAppHandler,
                    supportedAssetsRemoteService: $0.supportedAssetsRemoteService,
                    featureFlagService: $0.featureFlagsService,
                    mainQueue: $0.mainQueue
                )
            }
        ),
    mainAppReducer
        .pullback(
            state: \.coreState,
            action: /AppAction.core,
            environment: {
                CoreAppEnvironment(
                    loadingViewPresenter: $0.loadingViewPresenter,
                    deeplinkHandler: $0.deeplinkHandler,
                    deeplinkRouter: $0.deeplinkRouter,
                    walletManager: $0.walletManager,
                    mobileAuthSyncService: $0.mobileAuthSyncService,
                    resetPasswordService: $0.resetPasswordService,
                    accountRecoveryService: $0.accountRecoveryService,
                    userService: $0.userService,
                    deviceVerificationService: $0.deviceVerificationService,
                    featureFlagsService: $0.featureFlagsService,
                    appFeatureConfigurator: $0.appFeatureConfigurator,
                    fiatCurrencySettingsService: $0.fiatCurrencySettingsService,
                    blockchainSettings: $0.blockchainSettings,
                    credentialsStore: $0.credentialsStore,
                    alertPresenter: $0.alertViewPresenter,
                    walletUpgradeService: $0.walletUpgradeService,
                    exchangeRepository: $0.exchangeRepository,
                    remoteNotificationServiceContainer: $0.remoteNotificationServiceContainer,
                    coincore: $0.coincore,
                    erc20CryptoAssetService: $0.erc20CryptoAssetService,
                    sharedContainer: $0.sharedContainer,
                    analyticsRecorder: $0.analyticsRecorder,
                    siftService: $0.siftService,
                    onboardingSettings: $0.onboardingSettings,
                    mainQueue: $0.mainQueue,
                    appStoreOpener: $0.appStoreOpener,
                    walletService: $0.walletService,
                    buildVersionProvider: $0.buildVersionProvider
                )
            }
        ),
    appReducerCore
)

// swiftlint:disable closure_body_length
let appReducerCore = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .appDelegate(.didFinishLaunching):
        return .init(value: .core(.start))
    case .appDelegate(.didEnterBackground):
        guard state.coreState.isLoggedIn else {
            return .none
        }
        return .fireAndForget {
            environment.portfolioSyncingService.sync()
        }
    case .appDelegate(.willEnterForeground):
        return Effect(value: .core(.appForegrounded))
    case .appDelegate(.handleDelayedEnterBackground):
        if environment.openBanking.isAuthorising {
            return .none
        }
        return .merge(
            .fireAndForget {
                if environment.walletManager.walletIsInitialized() {
                    if environment.blockchainSettings.guid != nil, environment.blockchainSettings.sharedKey != nil {
                        environment.blockchainSettings.hasEndedFirstSession = true
                    }
                    environment.walletManager.close()
                }
            },
            .fireAndForget {
                environment.urlSession.reset {
                    Logger.shared.debug("URLSession reset completed.")
                }
            }
        )
    case .appDelegate(.userActivity(let activity)):
        state.appSettings.userActivityHandled = environment.deeplinkAppHandler.canHandle(
            deeplink: .userActivity(activity)
        )
        return environment.deeplinkAppHandler
            .handle(deeplink: .userActivity(activity))
            .catchToEffect()
            .cancellable(id: AppCancellations.DeeplinkId())
            .map { result in
                guard let data = result.successData else {
                    return AppAction.core(.none)
                }
                return AppAction.core(.deeplink(data))
            }
    case .appDelegate(.open(let url)):
        state.appSettings.urlHandled = environment.deeplinkAppHandler.canHandle(deeplink: .url(url))
        return environment.deeplinkAppHandler
            .handle(deeplink: .url(url))
            .catchToEffect()
            .cancellable(id: AppCancellations.DeeplinkId())
            .map { result in
                guard let data = result.successData else {
                    return AppAction.core(.none)
                }
                return AppAction.core(.deeplink(data))
            }
    case .core(.onboarding(.forgetWallet)):
        return .none
    case .core(.start):
        return .merge(
            environment.featureFlagsService
                .isEnabled(.local(.nativeWalletPayload))
                .eraseToEffect()
                .map { isEnabled in
                    guard isEnabled else {
                        return .none
                    }
                    return .walletPersistence(.begin)
                },
            Effect(value: .core(.onboarding(.start)))
        )
    case .walletPersistence(.begin):
        let crashlyticsRecorder = environment.crashlyticsRecorder
        return environment.walletRepoPersistence
            .beginPersisting()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .cancellable(
                id: AppCancellations.WalletPersistenceId(),
                cancelInFlight: true
            )
            .map { AppAction.walletPersistence(.persisted($0)) }
    case .walletPersistence(.persisted(.failure(let error))):
        // record the error if we encounter one and restart the persistence
        environment.crashlyticsRecorder.error(error)
        return .concatenate(
            .cancel(id: AppCancellations.WalletPersistenceId()),
            Effect(value: .walletPersistence(.begin))
        )
    case .walletPersistence(.persisted(.success)):
        return .none
    case .none:
        return .none
    default:
        return .none
    }
}

// swiftlint:enable closure_body_length
