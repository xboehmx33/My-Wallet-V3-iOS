// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import ComposableNavigation
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

    func test_enter_into_should_update_welcome_route() {
        let routes: [WelcomeRoute] = [
            .createWallet,
            .emailLogin,
            .restoreWallet,
            .manualLogin,
            .secondPassword
        ]
        routes.forEach { routeValue in
            testStore.send(.enter(into: routeValue)) { state in
                switch routeValue {
                case .createWallet:
                    state.createWalletState = .init(context: .createWallet)
                case .emailLogin:
                    state.emailLoginState = .init()
                case .restoreWallet:
                    state.restoreWalletState = .init(context: .restoreWallet)
                case .manualLogin:
                    state.manualCredentialsState = .init()
                case .secondPassword:
                    state.secondPasswordNoticeState = .init()
                }
                state.route = RouteIntent(route: routeValue, action: .enterInto())
            }
        }
    }

    func test_close_email_login_should_reset_state() {
        testStore.send(.enter(into: .emailLogin)) { state in
            state.route = RouteIntent(route: .emailLogin, action: .enterInto())
            state.emailLoginState = .init()
        }
        testStore.send(.emailLogin(.closeButtonTapped))
        testStore.receive(.dismiss()) { state in
            state.route = nil
            state.emailLoginState = nil
        }
    }

    func test_close_create_wallet_should_reset_state() {
        testStore.send(.enter(into: .createWallet)) { state in
            state.route = RouteIntent(route: .createWallet, action: .enterInto())
            state.createWalletState = .init(context: .createWallet)
        }
        testStore.send(.createWallet(.closeButtonTapped))
        testStore.receive(.dismiss()) { state in
            state.route = nil
            state.createWalletState = nil
        }
    }

    func test_secondPassword_modal_can_be_presented() {
        // given (we're in a flow)
        BuildFlag.isInternal = true
        testStore.send(.enter(into: .manualLogin)) { state in
            state.route = RouteIntent(route: .manualLogin, action: .enterInto())
            state.manualCredentialsState = .init()
        }

        // when
        testStore.send(.informSecondPasswordDetected)
        testStore.receive(.enter(into: .secondPassword)) { state in
            state.route = RouteIntent(route: .secondPassword, action: .enterInto())
            state.secondPasswordNoticeState = .init()
        }
    }

    func test_secondPassword_modal_can_be_dismissed_from_close_button() {
        // given (we're in a flow)
        BuildFlag.isInternal = true
        testStore.send(.enter(into: .manualLogin)) { state in
            state.route = RouteIntent(route: .manualLogin, action: .enterInto())
            state.manualCredentialsState = .init()
        }

        // when
        testStore.send(.informSecondPasswordDetected)
        testStore.receive(.enter(into: .secondPassword)) { state in
            state.route = RouteIntent(route: .secondPassword, action: .enterInto())
            state.secondPasswordNoticeState = .init()
        }

        // when
        testStore.send(.secondPasswordNotice(.closeButtonTapped))
        testStore.receive(.dismiss()) { state in
            state.route = nil
            state.manualCredentialsState = nil
            state.secondPasswordNoticeState = nil
        }
    }

    func test_secondPassword_modal_can_be_dismissed_interactively() {
        // given (we're in a flow)
        BuildFlag.isInternal = true
        testStore.send(.enter(into: .manualLogin)) { state in
            state.route = RouteIntent(route: .manualLogin, action: .enterInto())
            state.manualCredentialsState = .init()
        }

        // when
        testStore.send(.informSecondPasswordDetected)
        testStore.receive(.enter(into: .secondPassword)) { state in
            state.route = RouteIntent(route: .secondPassword, action: .enterInto())
            state.secondPasswordNoticeState = .init()
        }

        // when
        testStore.send(.secondPasswordNotice(.closeButtonTapped))
        testStore.receive(.dismiss()) { state in
            state.route = nil
            state.manualCredentialsState = nil
            state.secondPasswordNoticeState = nil
        }
    }
}
