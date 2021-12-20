// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import ComposableArchitecture
import DIKit
import ERC20Kit
import FeatureAuthenticationDomain
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import RxSwift
import WalletPayloadKit
import XCTest

@testable import Blockchain
@testable import ComposableNavigation
@testable import FeatureAppDomain
@testable import FeatureAppUI
@testable import FeatureAuthenticationMock
@testable import FeatureAuthenticationUI

// swiftlint:disable file_length
// swiftlint:disable type_body_length
final class MainAppReducerTests: XCTestCase {

    var mockWalletManager: WalletManager!
    var mockMobileAuthSyncService: MockMobileAuthSyncService!
    var mockResetPasswordService: MockResetPasswordService!
    var mockAccountRecoveryService: MockAccountRecoveryService!
    var mockDeviceVerificationService: MockDeviceVerificationService!
    var mockWallet: MockWallet! = MockWallet()
    var mockReactiveWallet = MockReactiveWallet()
    var mockSettingsApp: MockBlockchainSettingsApp!
    var mockCredentialsStore: CredentialsStoreAPIMock!
    var mockAlertPresenter: MockAlertViewPresenter!
    var mockWalletUpgradeService: MockWalletUpgradeService!
    var mockExchangeAccountRepository: MockExchangeAccountRepository!
    var mockRemoteNotificationAuthorizer: MockRemoteNotificationAuthorizer!
    var mockRemoteNotificationServiceContainer: MockRemoteNotificationServiceContainer!
    var mockCoincore: MockCoincore!
    var mockFeatureConfigurator: MockFeatureConfigurator!
    var mockAnalyticsRecorder: MockAnalyticsRecorder!
    var mockSiftService: MockSiftService!
    var onboardingSettings: MockOnboardingSettings!
    var mockMainQueue: TestSchedulerOf<DispatchQueue>!
    var mockDeepLinkHandler: MockDeepLinkHandler!
    var mockDeepLinkRouter: MockDeepLinkRouter!
    var mockFeatureFlagsService: MockFeatureFlagsService!
    var mockFiatCurrencySettingsService: FiatCurrencySettingsServiceMock!
    var mockAppStoreOpener: MockAppStoreOpener!
    var mockERC20CryptoAssetService: ERC20CryptoAssetServiceMock!

    var mockWalletService: WalletService!

    var testStore: TestStore<
        CoreAppState,
        CoreAppState,
        CoreAppAction,
        CoreAppAction,
        CoreAppEnvironment
    >!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockSettingsApp = MockBlockchainSettingsApp()
        mockWalletManager = WalletManager(
            wallet: mockWallet,
            appSettings: mockSettingsApp,
            reactiveWallet: mockReactiveWallet
        )
        mockMobileAuthSyncService = MockMobileAuthSyncService()
        mockResetPasswordService = MockResetPasswordService()
        mockAccountRecoveryService = MockAccountRecoveryService()
        mockDeviceVerificationService = MockDeviceVerificationService()
        mockCredentialsStore = CredentialsStoreAPIMock()
        mockAlertPresenter = MockAlertViewPresenter()
        mockWalletUpgradeService = MockWalletUpgradeService()
        mockExchangeAccountRepository = MockExchangeAccountRepository()
        mockRemoteNotificationAuthorizer = MockRemoteNotificationAuthorizer(
            expectedAuthorizationStatus: UNAuthorizationStatus.authorized,
            authorizationRequestExpectedStatus: .success(())
        )
        mockRemoteNotificationServiceContainer = MockRemoteNotificationServiceContainer(
            authorizer: mockRemoteNotificationAuthorizer
        )
        mockCoincore = MockCoincore()
        mockFeatureConfigurator = MockFeatureConfigurator()
        mockAnalyticsRecorder = MockAnalyticsRecorder()
        mockSiftService = MockSiftService()
        onboardingSettings = MockOnboardingSettings()
        mockMainQueue = DispatchQueue.test
        mockDeepLinkHandler = MockDeepLinkHandler()
        mockDeepLinkRouter = MockDeepLinkRouter()
        mockFeatureFlagsService = MockFeatureFlagsService()
        mockFiatCurrencySettingsService = FiatCurrencySettingsServiceMock(expectedCurrency: .USD)
        mockAppStoreOpener = MockAppStoreOpener()
        mockERC20CryptoAssetService = ERC20CryptoAssetServiceMock()

        mockWalletService = WalletService(
            fetch: { _ in .empty() },
            refetch: { _, _ in .empty() }
        )

        testStore = TestStore(
            initialState: CoreAppState(),
            reducer: mainAppReducer,
            environment: CoreAppEnvironment(
                loadingViewPresenter: LoadingViewPresenter(),
                deeplinkHandler: mockDeepLinkHandler,
                deeplinkRouter: mockDeepLinkRouter,
                walletManager: mockWalletManager,
                mobileAuthSyncService: mockMobileAuthSyncService,
                resetPasswordService: mockResetPasswordService,
                accountRecoveryService: mockAccountRecoveryService,
                userService: MockNabuUserService(),
                deviceVerificationService: mockDeviceVerificationService,
                featureFlagsService: mockFeatureFlagsService,
                appFeatureConfigurator: mockFeatureConfigurator,
                fiatCurrencySettingsService: mockFiatCurrencySettingsService,
                blockchainSettings: mockSettingsApp,
                credentialsStore: mockCredentialsStore,
                alertPresenter: mockAlertPresenter,
                walletUpgradeService: mockWalletUpgradeService,
                exchangeRepository: mockExchangeAccountRepository,
                remoteNotificationServiceContainer: mockRemoteNotificationServiceContainer,
                coincore: mockCoincore,
                erc20CryptoAssetService: mockERC20CryptoAssetService,
                sharedContainer: SharedContainerUserDefaults(),
                analyticsRecorder: mockAnalyticsRecorder,
                siftService: mockSiftService,
                onboardingSettings: onboardingSettings,
                mainQueue: mockMainQueue.eraseToAnyScheduler(),
                appStoreOpener: mockAppStoreOpener,
                walletService: mockWalletService,
                buildVersionProvider: { "" }
            )
        )
    }

    override func tearDownWithError() throws {
        mockSettingsApp = nil
        mockWalletManager = nil
        mockMobileAuthSyncService = nil
        mockResetPasswordService = nil
        mockAccountRecoveryService = nil
        mockDeviceVerificationService = nil
        mockCredentialsStore = nil
        mockAlertPresenter = nil
        mockWalletUpgradeService = nil
        mockExchangeAccountRepository = nil
        mockRemoteNotificationAuthorizer = nil
        mockRemoteNotificationServiceContainer = nil
        mockCoincore = nil
        mockFeatureConfigurator = nil
        mockAnalyticsRecorder = nil
        mockSiftService = nil
        onboardingSettings = nil
        mockMainQueue = nil
        mockDeepLinkHandler = nil
        mockDeepLinkRouter = nil
        mockFeatureFlagsService = nil
        mockFiatCurrencySettingsService = nil
        mockWalletService = nil
        testStore = nil

        try super.tearDownWithError()
    }

    func test_verify_initial_state_is_correct() {
        let state = CoreAppState()
        XCTAssertNotNil(state.onboarding)
        XCTAssertNil(state.loggedIn)
    }

    func test_syncPinKeyWithICloud() {
        // given
        mockSettingsApp.isPairedWithWallet = true

        // method is implementing fireAndForget
        syncPinKeyWithICloud(
            blockchainSettings: mockSettingsApp,
            credentialsStore: mockCredentialsStore
        )

        XCTAssertFalse(mockCredentialsStore.synchronizeCalled)

        // given
        mockSettingsApp.isPairedWithWallet = false
        mockSettingsApp.guid = "a"
        mockSettingsApp.sharedKey = "b"

        // method is implementing fireAndForget
        syncPinKeyWithICloud(
            blockchainSettings: mockSettingsApp,
            credentialsStore: mockCredentialsStore
        )

        XCTAssertFalse(mockCredentialsStore.synchronizeCalled)

        // given
        mockSettingsApp.isPairedWithWallet = false
        mockSettingsApp.encryptedPinPassword = "a"
        mockSettingsApp.pinKey = "b"

        // method is implementing fireAndForget
        syncPinKeyWithICloud(
            blockchainSettings: mockSettingsApp,
            credentialsStore: mockCredentialsStore
        )

        XCTAssertFalse(mockCredentialsStore.synchronizeCalled)

        // given
        mockSettingsApp.isPairedWithWallet = false
        mockSettingsApp.pinKey = nil
        mockSettingsApp.encryptedPinPassword = nil
        mockSettingsApp.guid = nil
        mockSettingsApp.sharedKey = nil

        // method is implementing fireAndForget
        syncPinKeyWithICloud(
            blockchainSettings: mockSettingsApp,
            credentialsStore: mockCredentialsStore
        )

        XCTAssertTrue(mockCredentialsStore.synchronizeCalled)
        XCTAssertTrue(mockCredentialsStore.expectedPinDataCalled)
    }

    func test_sending_start_should_correct_outputs() {
        testStore.send(.start) { state in
            state.onboarding = Onboarding.State()
            state.loggedIn = nil
        }
        XCTAssertTrue(mockFeatureConfigurator.initializeCalled)
    }

    func test_verify_didDecryptWallet_action_updates_appSettings() {
        testStore.send(
            .didDecryptWallet(.init(guid: "a", sharedKey: "b", passwordPartHash: "c"))
        )
        testStore.receive(.resetVerificationStatusIfNeeded(guid: "a", sharedKey: "b"))
        XCTAssertNotNil(testStore.environment.blockchainSettings.guid)
        XCTAssertEqual(testStore.environment.blockchainSettings.guid, "a")

        XCTAssertNotNil(testStore.environment.blockchainSettings.sharedKey)
        XCTAssertEqual(testStore.environment.blockchainSettings.sharedKey, "b")
    }

    func test_trying_to_login_withSecondPassword_account_displays_notice() {
        mockWallet.mockNeedsSecondPassword = true
        mockSettingsApp.guid = nil
        mockSettingsApp.sharedKey = nil
        mockSettingsApp.isPinSet = false

        testStore.send(.onboarding(.start)) { state in
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.welcomeState = .init()
        }

        testStore.receive(.onboarding(.welcomeScreen(.start)))
        testStore.receive(.onboarding(.welcomeScreen(.setManualPairingEnabled))) { state in
            state.onboarding?.welcomeState?.manualPairingEnabled = true
        }
        testStore.send(.onboarding(.welcomeScreen(.enter(into: .manualLogin)))) { state in
            state.onboarding?.welcomeState?.route = RouteIntent(route: .manualLogin, action: .enterInto())
            state.onboarding?.welcomeState?.manualCredentialsState = .init()
        }
        testStore.send(
            .onboarding(
                .welcomeScreen(
                    .manualPairing(
                        .walletPairing(
                            .decryptWalletWithPassword("password")
                        )
                    )
                )
            )
        ) { state in
            state.onboarding?.welcomeState?.manualCredentialsState?.isLoading = true
        }

        testStore.receive(.onboarding(.welcomeScreen(.requestedToDecryptWallet("password"))))
        testStore.receive(.fetchWallet(password: "password"))
        testStore.receive(.authenticate)
        mockMainQueue.advance(by: .seconds(1))
        testStore.receive(.doFetchWallet(password: "password"))
        mockSettingsApp.guid = String(repeating: "a", count: 36)
        mockSettingsApp.sharedKey = String(repeating: "b", count: 36)
        XCTAssertTrue(mockWallet.fetchCalled)
        mockWallet.load(
            withGuid: mockSettingsApp.guid!,
            sharedKey: mockSettingsApp.sharedKey!,
            password: "password".passwordPartHash
        )
        mockMainQueue.advance()

        // wallet decryptions still expects the original values
        let decryption = WalletDecryption(
            guid: String(repeating: "a", count: 36),
            sharedKey: String(repeating: "b", count: 36),
            passwordPartHash: nil
        )
        testStore.receive(.didDecryptWallet(decryption))
        testStore.receive(.authenticated(.success(true)))

        // Assert that both of these values are nil
        XCTAssertNil(mockSettingsApp.guid)
        XCTAssertNil(mockSettingsApp.sharedKey)

        testStore.receive(.onboarding(.informSecondPasswordDetected))
        testStore.receive(.onboarding(.welcomeScreen(.informSecondPasswordDetected)))
        testStore.receive(.onboarding(.welcomeScreen(.enter(into: .secondPassword)))) { state in
            state.onboarding?.welcomeState?.route = RouteIntent(route: .secondPassword, action: .enterInto())
            state.onboarding?.welcomeState?.secondPasswordNoticeState = .init()
        }
    }

    func test_sending_success_authentication_from_password_required_screen() {
        // given valid parameters
        mockSettingsApp.guid = String(repeating: "a", count: 36)
        mockSettingsApp.sharedKey = String(repeating: "b", count: 36)
        mockSettingsApp.isPinSet = false
        testStore.send(.onboarding(.start)) { state in
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.passwordScreen = .init()
        }

        // password screen should start
        testStore.receive(.onboarding(.passwordScreen(.start)))

        // when authenticating
        testStore.send(.onboarding(.passwordScreen(.authenticate("password"))))

        testStore.receive(.fetchWallet(password: "password"))
        testStore.receive(.authenticate)
        mockMainQueue.advance(by: .seconds(1))
        testStore.receive(.doFetchWallet(password: "password"))
        XCTAssertTrue(mockWallet.fetchCalled)
        mockWallet.load(
            withGuid: mockSettingsApp.guid!,
            sharedKey: mockSettingsApp.sharedKey!,
            password: "password".passwordPartHash
        )
        mockMainQueue.advance()

        let decryption = WalletDecryption(
            guid: mockSettingsApp.guid,
            sharedKey: mockSettingsApp.sharedKey,
            passwordPartHash: nil
        )
        testStore.receive(.didDecryptWallet(decryption))
        testStore.receive(.resetVerificationStatusIfNeeded(guid: decryption.guid, sharedKey: decryption.sharedKey))
        testStore.receive(.authenticated(.success(true)))
        testStore.receive(.setupPin) { state in
            state.onboarding?.pinState = .init()
            state.onboarding?.passwordScreen = nil
        }
        testStore.receive(.onboarding(.pin(.create))) { state in
            state.onboarding?.pinState?.creating = true
        }
    }

    func test_sending_success_authentication_from_pin() {
        // given valid parameters
        mockSettingsApp.guid = String(repeating: "a", count: 36)
        mockSettingsApp.sharedKey = String(repeating: "b", count: 36)
        mockSettingsApp.isPinSet = true
        testStore.send(.onboarding(.start)) { state in
            state.onboarding = .init()
            state.onboarding?.pinState = .init()
            state.onboarding?.passwordScreen = nil
        }

        // password screen should start
        testStore.receive(.onboarding(.pin(.authenticate))) { state in
            state.onboarding?.pinState?.authenticate = true
        }

        // when authenticating
        testStore.send(.onboarding(.pin(.handleAuthentication("password"))))

        testStore.receive(.fetchWallet(password: "password"))
        testStore.receive(.authenticate)
        mockMainQueue.advance(by: .seconds(1))
        testStore.receive(.doFetchWallet(password: "password"))
        XCTAssertTrue(mockWallet.fetchCalled)
        mockWallet.load(
            withGuid: mockSettingsApp.guid!,
            sharedKey: mockSettingsApp.sharedKey!,
            password: "password".passwordPartHash
        )

        mockMainQueue.advance()

        let decryption = WalletDecryption(
            guid: mockSettingsApp.guid,
            sharedKey: mockSettingsApp.sharedKey,
            passwordPartHash: nil
        )
        testStore.receive(.didDecryptWallet(decryption))
        testStore.receive(.resetVerificationStatusIfNeeded(guid: decryption.guid, sharedKey: decryption.sharedKey))
        testStore.receive(.authenticated(.success(true)))
        testStore.receive(.initializeWallet)
        mockReactiveWallet.mockState.on(.next(.initialized))
        mockMainQueue.advance()
        mockWalletUpgradeService.needsWalletUpgradeRelay.on(.next(false))
        testStore.receive(.walletInitialized)
        mockMainQueue.advance()
        testStore.receive(.walletNeedsUpgrade(false))
        testStore.receive(.prepareForLoggedIn)
        testStore.receive(.proceedToLoggedIn(.success(true))) { state in
            state.onboarding = nil
            state.loggedIn = .init()
        }
        let context = LoggedIn.Context.none
        testStore.receive(.loggedIn(.start(context)))
        testStore.receive(.mobileAuthSync(isLogin: true))

        mockMainQueue.advance()
        // send logout to clear pending effects after logged in.
        testStore.send(.loggedIn(.logout)) { state in
            state.loggedIn = nil
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.passwordScreen = .init()
        }
        testStore.receive(.onboarding(.passwordScreen(.start)))
    }

    func test_creating_wallet() {
        mockSettingsApp.guid = nil
        mockSettingsApp.sharedKey = nil
        mockSettingsApp.isPinSet = false
        mockFeatureFlagsService.enable(.local(.disableGUIDLogin)).subscribe().store(in: &cancellables)

        testStore.send(.onboarding(.start)) { state in
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.welcomeState = .init()
        }

        testStore.receive(.onboarding(.welcomeScreen(.start)))

        testStore.send(.onboarding(.welcomeScreen(.enter(into: .createWallet)))) { state in
            state.onboarding?.welcomeState?.route = RouteIntent(route: .createWallet, action: .enterInto())
            state.onboarding?.welcomeState?.createWalletState = .init(context: .createWallet)
            state.onboarding?.walletCreationContext = .new
        }
        testStore.send(.onboarding(.welcomeScreen(.requestedToCreateWallet("", "a-password"))))
        testStore.receive(.createWallet(email: "", newPassword: "a-password"))
        testStore.receive(.create)

        let guid = String(repeating: "a", count: 36)
        let sharedKey = String(repeating: "b", count: 36)
        // we need to assign this here as the WalletManager+Rx gets the password hash the legacy password
        mockWalletManager.legacyRepository.legacyPassword = "a-password"
        mockWallet.newAccount("a-password", email: "")
        mockMainQueue.advance()

        let walletCreation = WalletCreation(
            guid: guid,
            sharedKey: sharedKey,
            password: "a-password"
        )
        testStore.receive(.authenticate)
        testStore.receive(.setInitialResidentialAddress(country: "US", state: "AK"))
        testStore.receive(.created(.success(walletCreation)))

        mockWallet.load(withGuid: guid, sharedKey: sharedKey, password: "a-password")
        mockMainQueue.advance()

        let walletDecryption = WalletDecryption(
            guid: guid,
            sharedKey: sharedKey,
            passwordPartHash: nil
        )
        testStore.receive(.authenticate)
        testStore.receive(.didDecryptWallet(walletDecryption))
        testStore.receive(
            .resetVerificationStatusIfNeeded(
                guid: walletDecryption.guid,
                sharedKey: walletDecryption.sharedKey
            )
        )
        testStore.receive(.authenticated(.success(true)))
        testStore.receive(.onboarding(.welcomeScreen(.dismiss()))) { state in
            state.onboarding?.welcomeState?.route = nil
            state.onboarding?.welcomeState?.createWalletState = nil
        }
        testStore.receive(.setupPin) { state in
            state.onboarding?.pinState = .init()
            state.onboarding?.passwordScreen = nil
        }
        testStore.receive(.onboarding(.pin(.create))) { state in
            state.onboarding?.pinState?.creating = true
        }
    }

    // swiftlint:disable function_body_length
    func test_restore_wallet_metadata_restore_context() {
        mockSettingsApp.guid = nil
        mockSettingsApp.sharedKey = nil
        mockSettingsApp.isPinSet = false
        mockFeatureFlagsService.enable(.local(.disableGUIDLogin)).subscribe().store(in: &cancellables)

        testStore.send(.onboarding(.start)) { state in
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.welcomeState = .init()
        }
        testStore.receive(.onboarding(.welcomeScreen(.start)))

        testStore.send(.onboarding(.welcomeScreen(.enter(into: .restoreWallet)))) { state in
            state.onboarding?.welcomeState?.route = RouteIntent(route: .restoreWallet, action: .enterInto())
            state.onboarding?.welcomeState?.restoreWalletState = .init(context: .restoreWallet)
            state.onboarding?.walletCreationContext = .recovery
        }

        testStore.send(
            .onboarding(
                .welcomeScreen(.restoreWallet(.restoreWallet(.metadataRecovery(seedPhrase: ""))))
            )
        )

        testStore.receive(.onboarding(.welcomeScreen(.requestedToRestoreWallet(.metadataRecovery(seedPhrase: "")))))
        testStore.receive(.metadataRestoreWallet(seedPhrase: "")) { state in
            state.onboarding?.walletRecoveryContext = .metadataRecovery
        }
        testStore.receive(.restore)
        mockWallet.recoverFromMetadata(withMnemonicPassphrase: "")
        mockMainQueue.advance()

        mockSettingsApp.guid = String(repeating: "a", count: 36)
        mockSettingsApp.sharedKey = String(repeating: "b", count: 36)
        mockWallet.load(
            withGuid: mockSettingsApp.guid!,
            sharedKey: mockSettingsApp.sharedKey!,
            password: "password".passwordPartHash
        )
        testStore.receive(.authenticate)
        mockMainQueue.advance()

        testStore.receive(.restored(.success(.noValue)))

        let decryption = WalletDecryption(
            guid: mockSettingsApp.guid,
            sharedKey: mockSettingsApp.sharedKey,
            passwordPartHash: nil
        )
        testStore.receive(.didDecryptWallet(decryption))
        testStore.receive(.resetVerificationStatusIfNeeded(guid: decryption.guid, sharedKey: decryption.sharedKey))
        testStore.receive(.authenticated(.success(true)))

        testStore.receive(
            .onboarding(.welcomeScreen(.restoreWallet(.setResetPasswordScreenVisible(true))))
        ) { state in
            state.onboarding?.welcomeState?.restoreWalletState?.resetPasswordState = .init()
            state.onboarding?.welcomeState?.restoreWalletState?.isResetPasswordScreenVisible = true
        }
        testStore.receive(.none)

        testStore.send(
            .onboarding(.welcomeScreen(.restoreWallet(.resetPassword(.reset(password: "password")))))
        ) { state in
            state.onboarding?.welcomeState?.restoreWalletState?.resetPasswordState?.isLoading = true
        }
        testStore.receive(.resetPassword(newPassword: "password"))
        mockMainQueue.advance()
        testStore.receive(.setupPin) { state in
            state.onboarding?.pinState = .init()
            state.onboarding?.passwordScreen = nil
        }
        testStore.receive(.onboarding(.pin(.create))) { state in
            state.onboarding?.pinState?.creating = true
        }
    }

    // swiftlint:disable function_body_length
    func test_restore_wallet_reset_account_context() {
        mockSettingsApp.guid = nil
        mockSettingsApp.sharedKey = nil
        mockSettingsApp.isPinSet = false
        mockFeatureFlagsService.enable(.local(.disableGUIDLogin)).subscribe().store(in: &cancellables)

        testStore.send(.onboarding(.start)) { state in
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.welcomeState = .init()
        }
        testStore.receive(.onboarding(.welcomeScreen(.start)))

        testStore.send(.onboarding(.welcomeScreen(.enter(into: .emailLogin)))) { state in
            state.onboarding?.welcomeState?.route = RouteIntent(route: .emailLogin, action: .enterInto())
            state.onboarding?.welcomeState?.emailLoginState = .init()
            state.onboarding?.walletCreationContext = .existing
        }

        testStore.send(.onboarding(.welcomeScreen(.emailLogin(.navigate(to: .verifyDevice))))) { state in
            state.onboarding?.welcomeState?.emailLoginState?.verifyDeviceState = .init(emailAddress: "")
            state.onboarding?.welcomeState?.emailLoginState?.route = RouteIntent(route: .verifyDevice, action: .navigateTo)
        }

        testStore.send(
            .onboarding(
                .welcomeScreen(.emailLogin(.verifyDevice(.navigate(to: .credentials))))
            )
        ) { state in
            state.onboarding?.welcomeState?.emailLoginState?.verifyDeviceState?
                .credentialsState = .init()
            state.onboarding?.welcomeState?.emailLoginState?.verifyDeviceState?
                .route = RouteIntent(route: .credentials, action: .navigateTo)
        }

        testStore.send(
            .onboarding(
                .welcomeScreen(.emailLogin(.verifyDevice(.credentials(.setTroubleLoggingInScreenVisible(true)))))
            )
        ) { state in
            state
                .onboarding?
                .welcomeState?
                .emailLoginState?
                .verifyDeviceState?
                .credentialsState?
                .isTroubleLoggingInScreenVisible = true
            state
                .onboarding?
                .welcomeState?
                .emailLoginState?
                .verifyDeviceState?
                .credentialsState?
                .seedPhraseState = .init(context: .troubleLoggingIn)
        }

        let nabuInfo = WalletInfo.NabuInfo(userId: "", recoveryToken: "")

        testStore.send(
            .onboarding(
                .welcomeScreen(
                    .emailLogin(
                        .verifyDevice(
                            .credentials(
                                .seedPhrase(
                                    .restoreWallet(
                                        .resetAccountRecovery(
                                            email: "",
                                            newPassword: "a-password",
                                            nabuInfo: nabuInfo
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
        testStore.receive(
            .onboarding(
                .welcomeScreen(
                    .requestedToRestoreWallet(
                        .resetAccountRecovery(email: "", newPassword: "a-password", nabuInfo: nabuInfo)
                    )
                )
            )
        ) { state in
            state.onboarding?.nabuInfoForResetAccount = nabuInfo
        }
        testStore.receive(.createWallet(email: "", newPassword: "a-password"))
        testStore.receive(.create)

        let guid = String(repeating: "a", count: 36)
        let sharedKey = String(repeating: "b", count: 36)
        // we need to assign this here as the WalletManager+Rx gets the password hash the legacy password
        mockWalletManager.legacyRepository.legacyPassword = "a-password"
        mockWallet.newAccount("a-password", email: "")
        mockMainQueue.advance()

        let walletCreation = WalletCreation(
            guid: guid,
            sharedKey: sharedKey,
            password: "a-password"
        )
        testStore.receive(.authenticate)

        testStore.receive(.created(.success(walletCreation)))
        testStore.receive(
            .recoverUser(
                guid: guid,
                sharedKey: sharedKey,
                userId: nabuInfo.userId,
                recoveryToken: nabuInfo.recoveryToken
            )
        )

        mockWallet.load(withGuid: guid, sharedKey: sharedKey, password: "a-password")
        mockMainQueue.advance()

        let walletDecryption = WalletDecryption(
            guid: guid,
            sharedKey: sharedKey,
            passwordPartHash: nil
        )
        testStore.receive(.didDecryptWallet(walletDecryption))
        testStore.receive(
            .resetVerificationStatusIfNeeded(
                guid: walletDecryption.guid,
                sharedKey: walletDecryption.sharedKey
            )
        )
        testStore.receive(.authenticated(.success(true))) { state in
            state.onboarding?.welcomeState?.route = RouteIntent(route: .emailLogin, action: .enterInto())
        }
        testStore.receive(.onboarding(.welcomeScreen(.dismiss()))) { state in
            state.onboarding?.welcomeState?.route = nil
            state.onboarding?.welcomeState?.emailLoginState = nil
            state.onboarding?.walletCreationContext = nil
        }
        testStore.receive(.setupPin) { state in
            state.onboarding?.pinState = .init()
            state.onboarding?.passwordScreen = nil
        }
        testStore.receive(.onboarding(.pin(.create))) { state in
            state.onboarding?.pinState?.creating = true
        }
        testStore.receive(.none)
    }

    func test_restore_wallet_import_context() {
        mockSettingsApp.guid = nil
        mockSettingsApp.sharedKey = nil
        mockSettingsApp.isPinSet = false
        mockFeatureFlagsService.enable(.local(.disableGUIDLogin)).subscribe().store(in: &cancellables)

        testStore.send(.onboarding(.start)) { state in
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.welcomeState = .init()
        }
        testStore.receive(.onboarding(.welcomeScreen(.start)))

        testStore.send(.onboarding(.welcomeScreen(.enter(into: .restoreWallet)))) { state in
            state.onboarding?.welcomeState?.route = RouteIntent(route: .restoreWallet, action: .enterInto())
            state.onboarding?.welcomeState?.restoreWalletState = .init(context: .restoreWallet)
            state.onboarding?.walletCreationContext = .recovery
        }

        testStore.send(
            .onboarding(
                .welcomeScreen(
                    .restoreWallet(
                        .restoreWallet(.importRecovery(email: "", newPassword: "", seedPhrase: ""))
                    )
                )
            )
        )
        testStore.receive(
            .onboarding(
                .welcomeScreen(
                    .requestedToRestoreWallet(
                        .importRecovery(
                            email: "",
                            newPassword: "",
                            seedPhrase: ""
                        )
                    )
                )
            )
        )
        testStore.receive(.importWallet(email: "", newPassword: "", seedPhrase: "")) { state in
            state.onboarding?.walletRecoveryContext = .importRecovery
        }
        testStore.receive(.restore)
        mockWallet.recover(withEmail: "", password: "", mnemonicPassphrase: "")
        mockMainQueue.advance()

        testStore.receive(.authenticate)
        let guid = String(repeating: "a", count: 36)
        let sharedKey = String(repeating: "b", count: 36)
        // we need to assign this here as the WalletManager+Rx gets the password hash the legacy password
        mockWalletManager.legacyRepository.legacyPassword = "a-password"
        mockWallet.load(withGuid: guid, sharedKey: sharedKey, password: "a-password")
        mockMainQueue.advance()

        testStore.receive(.restored(.success(.noValue)))

        let walletDecryption = WalletDecryption(
            guid: guid,
            sharedKey: sharedKey,
            passwordPartHash: "a-password".passwordPartHash
        )
        testStore.receive(.didDecryptWallet(walletDecryption))
        testStore.receive(.resetVerificationStatusIfNeeded(guid: guid, sharedKey: sharedKey))
        testStore.receive(.authenticated(.success(true))) { state in
            state.onboarding?.welcomeState?.route = RouteIntent(route: .restoreWallet, action: .enterInto())
        }
        testStore.receive(.onboarding(.welcomeScreen(.dismiss()))) { state in
            state.onboarding?.welcomeState?.route = nil
            state.onboarding?.welcomeState?.restoreWalletState = nil
            state.onboarding?.walletCreationContext = nil
        }
        testStore.receive(.setupPin) { state in
            state.onboarding?.pinState = .init()
            state.onboarding?.passwordScreen = nil
        }
        testStore.receive(.onboarding(.pin(.create))) { state in
            state.onboarding?.pinState?.creating = true
        }
        testStore.receive(.none)
    }

    func test_sending_logout_should_perform_cleanup_and_display_password_screen() {
        testStore.send(.proceedToLoggedIn(.success(true))) { state in
            state.loggedIn = .init()
            state.onboarding = nil
        }
        mockMainQueue.advance()

        testStore.receive(.loggedIn(.start(.none)))
        testStore.receive(.mobileAuthSync(isLogin: true))
        mockMainQueue.advance()

        testStore.send(.loggedIn(.logout)) { state in
            state.loggedIn = nil
            state.onboarding = .init(pinState: nil, walletUpgradeState: nil, passwordScreen: .init())
        }

        XCTAssertTrue(mockAnalyticsRecorder.recordEventCalled.called)
        XCTAssertNotNil(mockAnalyticsRecorder.recordEventCalled.event)
        XCTAssertEqual(
            mockAnalyticsRecorder.recordEventCalled.event!.name,
            AnalyticsEvents.New.Navigation.signedOut.name
        )

        XCTAssertTrue(mockSiftService.removeUserIdCalled)
        XCTAssertTrue(mockSettingsApp.resetCalled)
        XCTAssertTrue(onboardingSettings.resetCalled)

        testStore.receive(.onboarding(.passwordScreen(.start)))
    }

    func test_sending_logout_should_perform_cleanup_and_pin_screen() {
        // given valid parameters
        mockSettingsApp.guid = String(repeating: "a", count: 36)
        mockSettingsApp.sharedKey = String(repeating: "b", count: 36)
        mockSettingsApp.isPinSet = true
        testStore.send(.onboarding(.start)) { state in
            state.onboarding = .init()
            state.onboarding?.passwordScreen = nil
        }

        testStore.receive(.onboarding(.pin(.authenticate))) { state in
            state.onboarding?.pinState?.authenticate = true
            state.onboarding?.passwordScreen = nil
        }

        testStore.send(.onboarding(.pin(.logout))) { state in
            state.loggedIn = nil
            state.onboarding = .init(pinState: nil, walletUpgradeState: nil, passwordScreen: .init())
        }

        XCTAssertTrue(mockAnalyticsRecorder.recordEventCalled.called)
        XCTAssertNotNil(mockAnalyticsRecorder.recordEventCalled.event)
        XCTAssertEqual(
            mockAnalyticsRecorder.recordEventCalled.event!.name,
            AnalyticsEvents.New.Navigation.signedOut.name
        )

        XCTAssertTrue(mockSiftService.removeUserIdCalled)
        XCTAssertTrue(mockSettingsApp.resetCalled)
        XCTAssertTrue(onboardingSettings.resetCalled)

        testStore.receive(.onboarding(.passwordScreen(.start)))
    }

    func test_sending_walletInitialized_should_check_if_wallet_upgrade_is_needed() {
        mockWalletUpgradeService.needsWalletUpgradeRelay.on(.next(true))

        testStore.send(.walletInitialized)
        mockMainQueue.advance()
        testStore.receive(.walletNeedsUpgrade(true)) { state in
            state.onboarding?.pinState = nil
            state.onboarding?.walletUpgradeState = WalletUpgrade.State()
            state.loggedIn = nil
        }

        testStore.receive(.onboarding(.walletUpgrade(.begin)))

        testStore.send(.onboarding(.walletUpgrade(.completed)))
        mockMainQueue.advance()
        testStore.receive(.prepareForLoggedIn)
        testStore.receive(.proceedToLoggedIn(.success(true))) { state in
            state.loggedIn = LoggedIn.State()
            state.onboarding = nil
        }
        testStore.receive(.loggedIn(.start(.none)))
        testStore.receive(.mobileAuthSync(isLogin: true))

        testStore.send(.loggedIn(.logout)) { state in
            state.loggedIn = nil
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.passwordScreen = .init()
        }

        testStore.receive(.onboarding(.passwordScreen(.start)))
    }

    func test_sending_walletInitialized_should_proceed_to_logged_in_when_no_upgrade_needed() {
        mockWalletUpgradeService.needsWalletUpgradeRelay.on(.next(false))
        testStore.send(.walletInitialized)
        mockMainQueue.advance()
        testStore.receive(.walletNeedsUpgrade(false))
        testStore.receive(.prepareForLoggedIn)
        testStore.receive(.proceedToLoggedIn(.success(true))) { state in
            state.loggedIn = LoggedIn.State()
            state.onboarding = nil
        }
        testStore.receive(.loggedIn(.start(.none)))
        testStore.receive(.mobileAuthSync(isLogin: true))

        testStore.send(.loggedIn(.logout)) { state in
            state.loggedIn = nil
            state.onboarding = .init()
            state.onboarding?.pinState = nil
            state.onboarding?.passwordScreen = .init()
        }

        testStore.receive(.onboarding(.passwordScreen(.start)))
    }

    func test_sending_appForegrounded_while_wallet_not_initialized_and_logged_in_state() {
        // given
        mockSettingsApp.guid = String(repeating: "a", count: 36)
        mockSettingsApp.sharedKey = String(repeating: "b", count: 36)
        mockSettingsApp.isPinSet = true

        mockWalletUpgradeService.needsWalletUpgradeRelay.on(.next(false))
        testStore.send(.walletInitialized)
        mockMainQueue.advance()
        testStore.receive(.walletNeedsUpgrade(false))
        testStore.receive(.prepareForLoggedIn)
        testStore.receive(.proceedToLoggedIn(.success(true))) { state in
            state.loggedIn = LoggedIn.State()
            state.onboarding = nil
        }
        testStore.receive(.loggedIn(.start(.none)))
        testStore.receive(.mobileAuthSync(isLogin: true))

        // when
        mockWallet.mockIsInitialized = false
        testStore.send(.appForegrounded)

        // then

        testStore.receive(.loggedIn(.stop))
        testStore.receive(.requirePin) { state in
            state.loggedIn = nil
            state.onboarding = .init()
        }
        testStore.receive(.onboarding(.start)) { state in
            state.onboarding?.pinState = .init()
        }
        testStore.receive(.onboarding(.pin(.authenticate))) { state in
            state.onboarding?.pinState?.authenticate = true
        }
    }

    func test_clearPinIfNeeded_correctly_clears_pin() {
        // given a hashed password
        mockSettingsApp.passwordPartHash = "a-hash"

        // 1. when the same password hash is used
        clearPinIfNeeded(for: "a-hash", appSettings: mockSettingsApp)

        // 1. then it should not clear the saved pin
        XCTAssertFalse(mockSettingsApp.clearPinCalled)

        // 2. when a different password hash is used (on password change)
        clearPinIfNeeded(for: "a-diff-hash", appSettings: mockSettingsApp)

        // 1. then it should clear the saved pin
        XCTAssertTrue(mockSettingsApp.clearPinCalled)
    }

    func test_wallet_decryption_outputs_decryption_failure_on_invalid_guid() {
        // note: the count of a guid and shared key should equal to 36
        // given a non valid guid
        let decryption = WalletDecryption(
            guid: "a",
            sharedKey: "b",
            passwordPartHash: "hashed"
        )

        // when
        let action = handleWalletDecryption(decryption)

        // then
        let expectedError = AuthenticationError(
            code: AuthenticationError.ErrorCode.errorDecryptingWallet,
            description: LocalizationConstants.Authentication.errorDecryptingWallet
        )

        XCTAssertEqual(CoreAppAction.decryptionFailure(expectedError), action)
    }

    func test_wallet_decryption_outputs_failure_on_invalid_sharedKey() {
        // note: the count of a guid and shared key should equal to 36
        // given a non valid sharedKey
        let guid = String(repeating: "a", count: 36)
        let decryption = WalletDecryption(
            guid: guid,
            sharedKey: "b",
            passwordPartHash: "hashed"
        )

        // when
        let action = handleWalletDecryption(decryption)

        // then
        let expectedError = AuthenticationError(
            code: AuthenticationError.ErrorCode.invalidSharedKey,
            description: LocalizationConstants.Authentication.invalidSharedKey
        )

        XCTAssertEqual(CoreAppAction.decryptionFailure(expectedError), action)
    }

    func test_wallet_decryption_outputs_success_on_valid_creds() {
        // note: the count of a guid and shared key should equal to 36
        // given a valid guid
        let guid = String(repeating: "a", count: 36)
        let sharedKey = String(repeating: "b", count: 36)
        let decryption = WalletDecryption(
            guid: guid,
            sharedKey: sharedKey,
            passwordPartHash: "hashed"
        )

        // when
        let action = handleWalletDecryption(decryption)

        // then
        XCTAssertEqual(CoreAppAction.didDecryptWallet(decryption), action)
    }

    func test_session_mismatch_deeplink_show_show_authorization() {
        mockFeatureFlagsService.enable(.remote(.pollingForEmailLogin))
            .subscribe().store(in: &cancellables)
        mockDeviceVerificationService.expectedSessionMismatch = true
        let requestInfo = LoginRequestInfo(
            sessionId: "",
            base64Str: "",
            details: DeviceVerificationDetails(originLocation: "", originIP: "", originBrowser: ""),
            timestamp: Date(timeIntervalSince1970: 1000)
        )
        testStore.assert(
            .send(.loginRequestReceived(
                deeplink: MockDeviceVerificationService.validDeeplink
            )),
            .do { self.mockMainQueue.advance() },
            .receive(
                .checkIfConfirmationRequired(
                    sessionId: "",
                    base64Str: ""
                )
            ),
            .receive(.proceedToDeviceAuthorization(requestInfo)) { state in
                state.deviceAuthorization = .init(loginRequestInfo: requestInfo)
            }
        )
    }
}

// swiftlint:enable type_body_length

// Copied from ERC20KitMock due to BlockchainTests not being able to import that dependency.
final class ERC20CryptoAssetServiceMock: ERC20CryptoAssetServiceAPI {

    var initializeCalled: Bool = false

    func initialize() -> AnyPublisher<Void, ERC20CryptoAssetServiceError> {
        initializeCalled = true
        return .just(())
    }
}
