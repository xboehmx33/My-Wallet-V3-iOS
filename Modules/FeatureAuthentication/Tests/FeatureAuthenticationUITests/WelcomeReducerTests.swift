// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
@testable import FeatureAuthenticationDomain
@testable import FeatureAuthenticationUI
@testable import ToolKit
import XCTest

// Mocks
@testable import AnalyticsKitMock
@testable import FeatureAuthenticationMock
@testable import ToolKitMock

final class WelcomeReducerTests: XCTestCase {

    private var dummyUserDefaults: UserDefaults!
    private var mockFeatureFlagsService: MockFeatureFlagsService!
    private var mockMainQueue: TestSchedulerOf<DispatchQueue>!
    private var testStore: TestStore<
        WelcomeState,
        WelcomeState,
        WelcomeAction,
        WelcomeAction,
        WelcomeEnvironment
    >!
    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockMainQueue = DispatchQueue.test
        dummyUserDefaults = UserDefaults(suiteName: "welcome.reducer.tests.defaults")!
        mockFeatureFlagsService = MockFeatureFlagsService()
        mockFeatureFlagsService.enable(.local(.disableGUIDLogin)).subscribe().store(in: &cancellables)
        testStore = TestStore(
            initialState: .init(),
            reducer: welcomeReducer,
            environment: WelcomeEnvironment(
                mainQueue: mockMainQueue.eraseToAnyScheduler(),
                passwordValidator: PasswordValidator(),
                sessionTokenService: MockSessionTokenService(),
                deviceVerificationService: MockDeviceVerificationService(),
                featureFlagsService: mockFeatureFlagsService,
                buildVersionProvider: { "Test Version" },
                errorRecorder: MockErrorRecorder(),
                externalAppOpener: MockExternalAppOpener(),
                analyticsRecorder: MockAnalyticsRecorder()
            )
        )
    }

    override func tearDownWithError() throws {
        BuildFlag.isInternal = false
        mockMainQueue = nil
        testStore = nil
        mockFeatureFlagsService = nil
        dummyUserDefaults.removeSuite(named: "welcome.reducer.tests.defaults")
        try super.tearDownWithError()
    }

    func test_verify_initial_state_is_correct() {
        let state = WelcomeState()
        XCTAssertNil(state.emailLoginState)
    }

    func test_start_updates_the_build_version() {
        testStore.send(.start) { state in
            state.buildVersion = "Test Version"
        }
    }

    func test_start_shows_manual_pairing_when_feature_flag_is_not_enabled_and_build_is_internal() {
        BuildFlag.isInternal = true
        mockFeatureFlagsService.disable(.local(.disableGUIDLogin)).subscribe().store(in: &cancellables)
        testStore.send(.start) { state in
            state.buildVersion = "Test Version"
        }
        testStore.receive(.setManualPairingEnabled) { state in
            state.manualPairingEnabled = true
        }
    }

    func test_start_does_not_shows_manual_pairing_when_feature_flag_is_not_enabled_and_build_is_not_internal() {
        BuildFlag.isInternal = false
        mockFeatureFlagsService.disable(.local(.disableGUIDLogin)).subscribe().store(in: &cancellables)
        testStore.send(.start) { state in
            state.buildVersion = "Test Version"
            state.manualPairingEnabled = false
        }
    }

    func test_present_screen_flow_updates_screen_flow() {
        let screenFlows: [WelcomeState.ScreenFlow] = [
            .welcomeScreen,
            .createWalletScreen,
            .newCreateWalletScreen,
            .emailLoginScreen,
            .restoreWalletScreen
        ]
        screenFlows.forEach { screenFlow in
            testStore.send(.presentScreenFlow(screenFlow)) { state in
                switch screenFlow {
                case .newCreateWalletScreen:
                    state.createWalletState = .init(isImportWallet: false)
                case .emailLoginScreen:
                    state.emailLoginState = .init()
                case .restoreWalletScreen:
                    state.restoreWalletState = .init()
                case .createWalletScreen, .manualLoginScreen, .createScreen:
                    break
                case .welcomeScreen:
                    state.createWalletState = nil
                    state.emailLoginState = nil
                    state.restoreWalletState = nil
                }
                state.screenFlow = screenFlow
            }
        }
    }

    func test_close_email_login_should_reset_state() {
        testStore.send(.presentScreenFlow(.emailLoginScreen)) { state in
            state.screenFlow = .emailLoginScreen
            state.emailLoginState = .init()
        }
        testStore.send(.emailLogin(.closeButtonTapped)) { state in
            state.screenFlow = .welcomeScreen
            state.emailLoginState = nil
        }
    }

    func test_close_create_wallet_should_reset_state() {
        testStore.send(.presentScreenFlow(.newCreateWalletScreen)) { state in
            state.screenFlow = .newCreateWalletScreen
            state.createWalletState = .init(isImportWallet: false)
        }
        testStore.send(.createWallet(.closeButtonTapped)) { state in
            state.screenFlow = .welcomeScreen
            state.createWalletState = nil
        }
    }

    func test_secondPassword_modal_can_be_presented() {
        // given (we're in a flow)
        BuildFlag.isInternal = true
        testStore.send(.presentScreenFlow(.manualLoginScreen)) { state in
            state.screenFlow = .manualLoginScreen
            state.manualCredentialsState = .init()
        }

        // when
        testStore.send(.informSecondPasswordDetected) { state in
            state.screenFlow = .welcomeScreen
            state.modals = .secondPasswordNoticeScreen
            state.secondPasswordNoticeState = .init()
        }
    }

    func test_secondPassword_modal_can_be_dismissed_from_close_button() {
        // given (we're in a flow)
        BuildFlag.isInternal = true
        testStore.send(.presentScreenFlow(.manualLoginScreen)) { state in
            state.screenFlow = .manualLoginScreen
            state.manualCredentialsState = .init()
        }

        // when
        testStore.send(.informSecondPasswordDetected) { state in
            state.screenFlow = .welcomeScreen
            state.modals = .secondPasswordNoticeScreen
            state.secondPasswordNoticeState = .init()
        }

        // when
        testStore.send(.secondPasswordNotice(.closeButtonTapped)) { state in
            state.screenFlow = .welcomeScreen
            state.modals = .none
            state.emailLoginState = nil
            state.secondPasswordNoticeState = nil
            state.manualCredentialsState = nil
        }
    }

    func test_secondPassword_modal_can_be_dismissed_interactively() {
        // given (we're in a flow)
        BuildFlag.isInternal = true
        testStore.send(.presentScreenFlow(.manualLoginScreen)) { state in
            state.screenFlow = .manualLoginScreen
            state.manualCredentialsState = .init()
        }

        // when
        testStore.send(.informSecondPasswordDetected) { state in
            state.screenFlow = .welcomeScreen
            state.modals = .secondPasswordNoticeScreen
            state.secondPasswordNoticeState = .init()
        }

        // when
        testStore.send(.modalDismissed(.secondPasswordNoticeScreen)) { state in
            state.screenFlow = .welcomeScreen
            state.modals = .none
            state.emailLoginState = nil
            state.secondPasswordNoticeState = nil
            state.manualCredentialsState = nil
        }
    }
}
