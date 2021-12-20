// Copyright © Blockchain Luxembourg S.A. All rights reserved.
// swiftlint:disable file_length

import AnalyticsKit
import BitcoinCashKit
import BitcoinChainKit
import BitcoinKit
import DIKit
import ERC20Kit
import EthereumKit
import FeatureAppUI
import FeatureAuthenticationData
import FeatureAuthenticationDomain
import FeatureDashboardUI
import FeatureDebugUI
import FeatureKYCDomain
import FeatureKYCUI
import FeatureOnboardingUI
import FeatureOpenBankingData
import FeatureOpenBankingDomain
import FeatureOpenBankingUI
import FeatureQRCodeScannerDomain
import FeatureSettingsDomain
import FeatureSettingsUI
import FeatureTransactionDomain
import FeatureTransactionUI
import FeatureWalletConnectData
import NetworkKit
import PlatformKit
import PlatformUIKit
import RemoteNotificationsKit
import RxToolKit
import StellarKit
import ToolKit
import WalletPayloadKit

// MARK: - Settings Dependencies

extension ExchangeCoordinator: FeatureSettingsUI.ExchangeCoordinating {}

extension UIApplication: PlatformKit.AppStoreOpening {}

extension Wallet: WalletRecoveryVerifing {}

// MARK: - Dashboard Dependencies

extension AnalyticsUserPropertyInteractor: FeatureDashboardUI.AnalyticsUserPropertyInteracting {}

extension AnnouncementPresenter: FeatureDashboardUI.AnnouncementPresenting {}

extension FeatureSettingsUI.BackupFundsRouter: FeatureDashboardUI.BackupRouterAPI {}

// MARK: - AnalyticsKit Dependencies

extension BlockchainSettings.App: AnalyticsKit.GuidRepositoryAPI {}

// MARK: - Blockchain Module

extension DependencyContainer {

    // swiftlint:disable closure_body_length
    static var blockchain = module {

        factory { NavigationRouter() as NavigationRouterAPI }

        single { OnboardingSettings() }

        single { InternetReachability() as InternetReachabilityAPI }

        factory { () -> OnboardingSettingsAPI in
            let settings: OnboardingSettings = DIKit.resolve()
            return settings as OnboardingSettingsAPI
        }

        factory { AirdropRouter() as AirdropRouterAPI }

        factory { AirdropCenterClient() as AirdropCenterClientAPI }

        factory { AirdropCenterService() as AirdropCenterServiceAPI }

        factory { DeepLinkHandler() as DeepLinkHandling }

        factory { DeepLinkRouter() as DeepLinkRouting }

        factory { UIDevice.current as DeviceInfo }

        factory { CrashlyticsRecorder() as MessageRecording }

        factory { CrashlyticsRecorder() as ErrorRecording }

        factory(tag: "CrashlyticsRecorder") { CrashlyticsRecorder() as Recording }

        factory { ExchangeClient() as ExchangeClientAPI }

        factory { RecoveryPhraseStatusProvider() as RecoveryPhraseStatusProviding }

        single { TradeLimitsMetadataService() as TradeLimitsMetadataServiceAPI }

        factory { SiftService() }

        factory { () -> FeatureAuthenticationDomain.SiftServiceAPI in
            let service: SiftService = DIKit.resolve()
            return service as FeatureAuthenticationDomain.SiftServiceAPI
        }

        factory { () -> PlatformKit.SiftServiceAPI in
            let service: SiftService = DIKit.resolve()
            return service as PlatformKit.SiftServiceAPI
        }

        single { SecondPasswordHelper() }

        factory { () -> SecondPasswordHelperAPI in
            let helper: SecondPasswordHelper = DIKit.resolve()
            return helper as SecondPasswordHelperAPI
        }

        factory { () -> SecondPasswordPresenterHelper in
            let helper: SecondPasswordHelper = DIKit.resolve()
            return helper as SecondPasswordPresenterHelper
        }

        factory { CustomerSupportChatClient() as CustomerSupportChatClientAPI }

        factory { CustomerSupportChatService() as CustomerSupportChatServiceAPI }

        factory { CustomerSupportChatRouter() as CustomerSupportChatRouterAPI }

        single { SecondPasswordPrompter() as SecondPasswordPromptable }

        single { SecondPasswordStore() as SecondPasswordStorable }

        single { () -> AppDeeplinkHandlerAPI in
            let appSettings: BlockchainSettings.App = DIKit.resolve()
            let isPinSet: () -> Bool = { appSettings.isPinSet }
            let deeplinkHandler = CoreDeeplinkHandler(
                markBitpayUrl: { BitpayService.shared.contentRelay.accept($0) },
                isBitPayURL: BitPayLinkRouter.isBitPayURL,
                isPinSet: isPinSet
            )
            let blockchainHandler = BlockchainLinksHandler(
                validHosts: BlockchainLinks.validLinks,
                validRoutes: BlockchainLinks.validRoutes
            )
            return AppDeeplinkHandler(
                deeplinkHandler: deeplinkHandler,
                blockchainHandler: blockchainHandler,
                firebaseHandler: FirebaseDeeplinkHandler()
            )
        }

        // MARK: ExchangeCoordinator

        factory { ExchangeCoordinator.shared }

        factory { () -> ExchangeCoordinating in
            let coordinator: ExchangeCoordinator = DIKit.resolve()
            return coordinator as ExchangeCoordinating
        }

        // MARK: - AuthenticationCoordinator

        factory { () -> AuthenticationCoordinating in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveAuthenticationCoordinating() as AuthenticationCoordinating
        }

        // MARK: - Dashboard

        factory { () -> AccountsRouting in
            let routing: TabSwapping = DIKit.resolve()
            return AccountsRouter(
                routing: routing
            )
        }

        factory { UIApplication.shared as AppStoreOpening }

        factory {
            BackupFundsRouter(
                entry: .custody,
                navigationRouter: NavigationRouter()
            ) as FeatureDashboardUI.BackupRouterAPI
        }

        factory { AnalyticsUserPropertyInteractor() as FeatureDashboardUI.AnalyticsUserPropertyInteracting }

        factory { AnnouncementPresenter() as FeatureDashboardUI.AnnouncementPresenting }

        factory { FiatBalanceCellProvider() as FiatBalanceCellProviding }

        factory { FiatBalanceCollectionViewInteractor() as FiatBalancesInteracting }

        factory { FiatBalanceCollectionViewPresenter(interactor: FiatBalanceCollectionViewInteractor())
            as FiatBalanceCollectionViewPresenting
        }

        factory { SimpleBuyAnalyticsService() as PlatformKit.SimpleBuyAnalayticsServicing }

        factory { WithdrawalRouter() as WithdrawalRouting }

        // MARK: - AppCoordinator

        single { LoggedInDependencyBridge() as LoggedInDependencyBridgeAPI }

        factory { () -> TabSwapping in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveTabSwapping() as TabSwapping
        }

        factory { () -> AppCoordinating in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveAppCoordinating() as AppCoordinating
        }

        factory { () -> FeatureDashboardUI.WalletOperationsRouting in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveWalletOperationsRouting() as FeatureDashboardUI.WalletOperationsRouting
        }

        factory { () -> BackupFlowStarterAPI in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveBackupFlowStarter() as BackupFlowStarterAPI
        }

        factory { () -> CashIdentityVerificationAnnouncementRouting in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveCashIdentityVerificationAnnouncementRouting()
                as CashIdentityVerificationAnnouncementRouting
        }

        factory { () -> InterestIdentityVerificationAnnouncementRouting in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveInterestIdentityVerificationAnnouncementRouting()
                as InterestIdentityVerificationAnnouncementRouting
        }

        factory { () -> SettingsStarterAPI in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveSettingsStarter() as SettingsStarterAPI
        }

        factory { () -> DrawerRouting in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveDrawerRouting() as DrawerRouting
        }

        factory { () -> LoggedInReloadAPI in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveLoggedInReload() as LoggedInReloadAPI
        }

        factory { () -> ClearOnLogoutAPI in
            EmptyClearOnLogout()
        }

        factory { () -> QRCodeScannerRouting in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveQRCodeScannerRouting() as QRCodeScannerRouting
        }

        factory { () -> ExternalActionsProviderAPI in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveExternalActionsProvider() as ExternalActionsProviderAPI
        }

        factory { () -> QRCodeScannerLinkerAPI in
            QRCodeScannerAdapter()
        }

        factory { () -> CryptoTargetQRCodeParserAdapter in
            QRCodeScannerAdapter()
        }

        // MARK: - WalletManager

        single { WalletManager() }

        factory { () -> WalletManagerAPI in
            let manager: WalletManager = DIKit.resolve()
            return manager as WalletManagerAPI
        }

        factory { () -> MnemonicAccessAPI in
            let walletManager: WalletManager = DIKit.resolve()
            return walletManager.wallet as MnemonicAccessAPI
        }

        factory { () -> WalletRepositoryProvider in
            let walletManager: WalletManager = DIKit.resolve()
            return walletManager as WalletRepositoryProvider
        }

        factory { () -> JSContextProviderAPI in
            let walletManager: WalletManager = DIKit.resolve()
            return walletManager as JSContextProviderAPI
        }

        factory { () -> WalletRecoveryVerifing in
            let walletManager: WalletManager = DIKit.resolve()
            return walletManager.wallet as WalletRecoveryVerifing
        }

        factory { () -> WalletConnectMetadataAPI in
            let walletManager: WalletManager = DIKit.resolve()
            return walletManager.wallet.walletConnect as WalletConnectMetadataAPI
        }

        // MARK: - BlockchainSettings.App

        single { KeychainItemSwiftWrapper() as KeychainItemWrapping }

        factory { LegacyPasswordProvider() as LegacyPasswordProviding }

        single { BlockchainSettings.App() }

        factory { () -> AppSettingsAPI in
            let app: BlockchainSettings.App = DIKit.resolve()
            return app as AppSettingsAPI
        }

        factory { () -> AppSettingsAuthenticating in
            let app: BlockchainSettings.App = DIKit.resolve()
            return app as AppSettingsAuthenticating
        }

        factory { () -> PermissionSettingsAPI in
            let app: BlockchainSettings.App = DIKit.resolve()
            return app
        }

        factory { () -> AppSettingsSecureChannel in
            let app: BlockchainSettings.App = DIKit.resolve()
            return app as AppSettingsSecureChannel
        }

        // MARK: - Settings

        factory { () -> RecoveryPhraseVerifyingServiceAPI in
            let manager: WalletManager = DIKit.resolve()
            return RecoveryPhraseVerifyingService(wallet: manager.wallet) as RecoveryPhraseVerifyingServiceAPI
        }

        // MARK: - AppFeatureConfigurator

        single { AppFeatureConfigurator() }

        factory { () -> FeatureConfiguratorAPI in
            let configurator: AppFeatureConfigurator = DIKit.resolve()
            return configurator
        }

        factory { () -> FeatureConfiguring in
            let featureFetching: AppFeatureConfigurator = DIKit.resolve()
            return featureFetching
        }

        factory { () -> FeatureFetching in
            let featureFetching: AppFeatureConfigurator = DIKit.resolve()
            return featureFetching
        }

        factory { () -> RxFeatureFetching in
            let featureFetching: AppFeatureConfigurator = DIKit.resolve()
            return featureFetching
        }

        factory { () -> RxFeatureVariantFetching in
            let featureFetching: AppFeatureConfigurator = DIKit.resolve()
            return featureFetching
        }

        // MARK: - UserInformationServiceProvider

        factory { () -> SettingsServiceAPI in
            let completeSettingsService: CompleteSettingsServiceAPI = DIKit.resolve()
            return completeSettingsService
        }

        factory { () -> FiatCurrencyServiceAPI in
            let completeSettingsService: CompleteSettingsServiceAPI = DIKit.resolve()
            return completeSettingsService
        }

        factory { () -> SupportedFiatCurrenciesServiceAPI in
            let completeSettingsService: CompleteSettingsServiceAPI = DIKit.resolve()
            return completeSettingsService
        }

        factory { () -> MobileSettingsServiceAPI in
            let completeSettingsService: CompleteSettingsServiceAPI = DIKit.resolve()
            return completeSettingsService
        }

        // MARK: - BlockchainDataRepository

        factory { BlockchainDataRepository() as DataRepositoryAPI }

        // MARK: - Ethereum Wallet

        factory { () -> EthereumWalletBridgeAPI in
            let manager: WalletManager = DIKit.resolve()
            return manager.wallet.ethereum
        }

        factory { () -> EthereumWalletAccountBridgeAPI in
            let manager: WalletManager = DIKit.resolve()
            return manager.wallet.ethereum
        }

        // MARK: - Stellar Wallet

        factory { StellarWallet() as StellarWalletBridgeAPI }

        factory { () -> BitcoinWalletBridgeAPI in
            let walletManager: WalletManager = DIKit.resolve()
            return walletManager.wallet.bitcoin
        }

        factory { () -> BitcoinChainSendBridgeAPI in
            let walletManager: WalletManager = DIKit.resolve()
            return walletManager.wallet.bitcoin
        }

        single { BitcoinCashWallet() as BitcoinCashWalletBridgeAPI }

        // MARK: Wallet Upgrade

        factory { WalletUpgrading() as WalletUpgradingAPI }

        // MARK: Remote Notifications

        factory { ExternalNotificationServiceProvider() as ExternalNotificationProviding }

        factory { () -> RemoteNotificationEmitting in
            let relay: RemoteNotificationRelay = DIKit.resolve()
            return relay as RemoteNotificationEmitting
        }

        factory { () -> RemoteNotificationBackgroundReceiving in
            let relay: RemoteNotificationRelay = DIKit.resolve()
            return relay as RemoteNotificationBackgroundReceiving
        }

        single { RemoteNotificationRelay() }

        // MARK: Helpers

        factory { UIApplication.shared as ExternalAppOpener }
        factory { UIApplication.shared as URLOpener }

        // MARK: KYC Module

        factory { () -> FeatureSettingsUI.KYCRouterAPI in
            KYCAdapter()
        }

        factory { () -> FeatureKYCDomain.EmailVerificationAPI in
            EmailVerificationAdapter(settingsService: DIKit.resolve())
        }

        factory { () -> PlatformUIKit.TierUpgradeRouterAPI in
            KYCAdapter()
        }

        // MARK: Onboarding Module

        // this must be kept in memory because of how PlatformUIKit.Router works, otherwise the flow crashes.
        single { () -> FeatureOnboardingUI.OnboardingRouterAPI in
            FeatureOnboardingUI.OnboardingRouter()
        }

        factory { () -> FeatureOnboardingUI.BuyCryptoRouterAPI in
            TransactionsAdapter()
        }

        factory { () -> FeatureOnboardingUI.EmailVerificationRouterAPI in
            KYCAdapter()
        }

        // MARK: Transactions Module

        factory { () -> TransactionsAdapterAPI in
            TransactionsAdapter()
        }

        factory { () -> PlatformUIKit.KYCRouting in
            KYCAdapter()
        }

        factory { () -> FeatureTransactionUI.KYCSDDServiceAPI in
            TransactionsKYCAdapter()
        }

        factory { () -> FeatureSettingsUI.PaymentMethodsLinkerAPI in
            PaymentMethodsLinkingAdapter()
        }

        // MARK: FeatureAuthentication Module

        factory { () -> AutoWalletPairingServiceAPI in
            let manager: WalletManager = DIKit.resolve()
            return AutoWalletPairingService(repository: manager.repository) as AutoWalletPairingServiceAPI
        }

        factory { () -> GuidServiceAPI in
            GuidService(
                sessionTokenRepository: DIKit.resolve(),
                client: DIKit.resolve()
            )
        }

        factory { () -> SessionTokenServiceAPI in
            sessionTokenServiceFactory(
                sessionRepository: DIKit.resolve()
            )
        }

        factory { () -> SMSServiceAPI in
            SMSService(
                client: DIKit.resolve(),
                credentialsRepository: DIKit.resolve(),
                sessionTokenRepository: DIKit.resolve()
            )
        }

        factory { () -> TwoFAWalletServiceAPI in
            let manager: WalletManager = DIKit.resolve()
            return TwoFAWalletService(
                client: DIKit.resolve(),
                repository: manager.repository,
                walletRepo: DIKit.resolve(),
                nativeWalletFlagEnabled: { nativeWalletFlagEnabled() }
            )
        }

        factory { () -> WalletPayloadServiceAPI in
            let manager: WalletManager = DIKit.resolve()
            return WalletPayloadService(
                client: DIKit.resolve(),
                repository: manager.repository,
                walletRepo: DIKit.resolve(),
                nativeWalletEnabledUse: nativeWalletEnabledUseImpl
            )
        }

        factory { () -> LoginServiceAPI in
            LoginService(
                payloadService: DIKit.resolve(),
                twoFAPayloadService: DIKit.resolve(),
                repository: DIKit.resolve()
            )
        }

        factory { () -> EmailAuthorizationServiceAPI in
            EmailAuthorizationService(guidService: DIKit.resolve()) as EmailAuthorizationServiceAPI
        }

        factory { () -> DeviceVerificationServiceAPI in
            let manager: WalletManager = DIKit.resolve()
            return DeviceVerificationService(
                sessionTokenRepository: manager.repository
            ) as DeviceVerificationServiceAPI
        }

        factory { RecaptchaClient(siteKey: AuthenticationKeys.googleRecaptchaSiteKey) }

        factory { GoogleRecaptchaService() as GoogleRecaptchaServiceAPI }

        // MARK: Analytics

        single { () -> AnalyticsKit.GuidRepositoryAPI in
            let guidRepository: BlockchainSettings.App = DIKit.resolve()
            return guidRepository as AnalyticsKit.GuidRepositoryAPI
        }

        single { () -> AnalyticsEventRecorderAPI in
            let firebaseAnalyticsServiceProvider = FirebaseAnalyticsServiceProvider()
            let userAgent = UserAgentProvider().userAgent ?? ""
            let nabuAnalyticsServiceProvider = NabuAnalyticsProvider(
                platform: .wallet,
                basePath: BlockchainAPI.shared.apiUrl,
                userAgent: userAgent,
                tokenProvider: DIKit.resolve(),
                guidProvider: DIKit.resolve()
            )
            return AnalyticsEventRecorder(analyticsServiceProviders: [
                firebaseAnalyticsServiceProvider,
                nabuAnalyticsServiceProvider
            ])
        }

        // MARK: Account Picker

        factory { () -> AccountPickerViewControllable in
            let controller = LoadableAccountPickerControllable()
            return controller as AccountPickerViewControllable
        }

        // MARK: Open Banking

        single { () -> OpenBanking in
            let builder: NetworkKit.RequestBuilder = DIKit.resolve(tag: DIKitContext.retail)
            let adapter: NetworkKit.NetworkAdapterAPI = DIKit.resolve(tag: DIKitContext.retail)
            let client = OpenBankingClient(
                requestBuilder: builder,
                network: adapter.network
            )
            return OpenBanking(banking: client)
        }
    }
}
