// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
@testable import ComposableNavigation
@testable import FeatureAuthenticationDomain
@testable import FeatureAuthenticationUI
import Localization
import ToolKit
import XCTest

// Mocks
@testable import AnalyticsKitMock
@testable import FeatureAuthenticationMock
@testable import ToolKitMock

final class VerifyDeviceReducerTests: XCTestCase {

    private var mockMainQueue: TestSchedulerOf<DispatchQueue>!
    private var mockFeatureFlagsService: MockFeatureFlagsService!
    private var testStore: TestStore<
        VerifyDeviceState,
        VerifyDeviceState,
        VerifyDeviceAction,
        VerifyDeviceAction,
        VerifyDeviceEnvironment
    >!
    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockMainQueue = DispatchQueue.test
        mockFeatureFlagsService = MockFeatureFlagsService()
        testStore = TestStore(
            initialState: .init(emailAddress: ""),
            reducer: verifyDeviceReducer,
            environment: .init(
                mainQueue: mockMainQueue.eraseToAnyScheduler(),
                deviceVerificationService: MockDeviceVerificationService(),
                featureFlagsService: mockFeatureFlagsService,
                errorRecorder: NoOpErrorRecorder(),
                externalAppOpener: MockExternalAppOpener(),
                analyticsRecorder: MockAnalyticsRecorder()
            )
        )
    }

    override func tearDownWithError() throws {
        mockMainQueue = nil
        mockFeatureFlagsService = nil
        testStore = nil
        try super.tearDownWithError()
    }

    func test_verify_initial_state_is_correct() {
        let state = VerifyDeviceState(emailAddress: "")
        XCTAssertNil(state.credentialsState)
        XCTAssertNil(state.route)
        XCTAssertEqual(state.credentialsContext, .none)
    }

    func test_on_appear_should_poll_wallet_info() {
        mockFeatureFlagsService.enable(.remote(.pollingForEmailLogin))
            .subscribe().store(in: &cancellables)
        testStore.assert(
            .send(.onAppear),
            .receive(.pollWalletInfo),
            .do { self.mockMainQueue.advance() },
            .receive(.didPolledWalletInfo(.success(MockDeviceVerificationService.mockWalletInfo))),
            .receive(.didExtractWalletInfo(MockDeviceVerificationService.mockWalletInfo)) { state in
                state.credentialsContext = .walletInfo(MockDeviceVerificationService.mockWalletInfo)
            },
            .receive(.navigate(to: .credentials)) { state in
                state.credentialsState = CredentialsState(
                    walletPairingState: WalletPairingState(
                        emailAddress: MockDeviceVerificationService.mockWalletInfo.email!,
                        emailCode: MockDeviceVerificationService.mockWalletInfo.emailCode,
                        walletGuid: MockDeviceVerificationService.mockWalletInfo.guid
                    )
                )
                state.route = RouteIntent(route: .credentials, action: .navigateTo)
            }
        )
    }

    func test_receive_valid_wallet_deeplink_should_update_wallet_info() {
        testStore.assert(
            .send(.didReceiveWalletInfoDeeplink(MockDeviceVerificationService.validDeeplink)),
            .do { self.mockMainQueue.advance() },
            .receive(.didExtractWalletInfo(MockDeviceVerificationService.mockWalletInfo)) { state in
                state.credentialsContext = .walletInfo(MockDeviceVerificationService.mockWalletInfo)
            },
            .receive(.navigate(to: .credentials)) { state in
                state.credentialsState = CredentialsState(
                    walletPairingState: WalletPairingState(
                        emailAddress: MockDeviceVerificationService.mockWalletInfo.email!,
                        emailCode: MockDeviceVerificationService.mockWalletInfo.emailCode,
                        walletGuid: MockDeviceVerificationService.mockWalletInfo.guid
                    )
                )
                state.route = RouteIntent(route: .credentials, action: .navigateTo)
            }
        )

        testStore.send(.didReceiveWalletInfoDeeplink(MockDeviceVerificationService.deeplinkWithValidGuid))
        mockMainQueue.advance()
        testStore.receive(.didExtractWalletInfo(MockDeviceVerificationService.mockWalletInfoWithGuidOnly)) { state in
            state.credentialsContext = .walletIdentifier(
                guid: MockDeviceVerificationService.mockWalletInfoWithGuidOnly.guid
            )
        }
        testStore.receive(.navigate(to: .credentials)) { state in
            state.credentialsState = CredentialsState(
                walletPairingState: WalletPairingState(
                    emailAddress: "",
                    walletGuid: MockDeviceVerificationService.mockWalletInfo.guid
                )
            )
        }
    }

    func test_deeplink_parsing_failure_should_fallback_to_wallet_identifier() {
        testStore.send(.didReceiveWalletInfoDeeplink(MockDeviceVerificationService.invalidDeeplink))
        mockMainQueue.advance()
        testStore.receive(.fallbackToWalletIdentifier) { state in
            state.credentialsContext = .walletIdentifier(guid: "")
        }
        testStore.receive(.navigate(to: .credentials)) { state in
            state.credentialsState = .init()
            state.route = RouteIntent(route: .credentials, action: .navigateTo)
        }
    }
}
