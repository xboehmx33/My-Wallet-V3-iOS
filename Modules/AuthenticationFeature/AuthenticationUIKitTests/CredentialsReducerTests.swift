// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import AuthenticationKit
@testable import AuthenticationUIKit
import ComposableArchitecture
import ToolKit
import XCTest

final class CredentialsReducerTests: XCTestCase {

    private var mockMainQueue: TestSchedulerOf<DispatchQueue>!
    private var mockPollingQueue: TestSchedulerOf<DispatchQueue>!
    private var testStore: TestStore<
        CredentialsState,
        CredentialsState,
        CredentialsAction,
        CredentialsAction,
        CredentialsEnvironment
    >!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockMainQueue = DispatchQueue.test
        mockPollingQueue = DispatchQueue.test
        testStore = TestStore(
            initialState: .init(),
            reducer: credentialsReducer,
            environment: .init(
                mainQueue: mockMainQueue.eraseToAnyScheduler(),
                pollingQueue: mockPollingQueue.eraseToAnyScheduler(),
                deviceVerificationService: MockDeviceVerificationService(),
                emailAuthorizationService: MockEmailAuthorizationService(),
                sessionTokenService: MockSessionTokenService(),
                smsService: MockSMSService(),
                loginService: MockLoginService(),
                wallet: MockWalletAuthenticationKitWrapper(),
                analyticsRecorder: MockAnalyticsRecorder(),
                errorRecorder: NoOpErrorRecorder()
            )
        )
    }

    override func tearDownWithError() throws {
        mockMainQueue = nil
        mockPollingQueue = nil
        testStore = nil
        try super.tearDownWithError()
    }

    func test_verify_initial_state_is_correct() {
        let state = CredentialsState()
        XCTAssertNotNil(state.twoFAState)
        XCTAssertNotNil(state.hardwareKeyState)
        XCTAssertEqual(state.emailAddress, "")
        XCTAssertEqual(state.walletGuid, "")
        XCTAssertEqual(state.emailCode, "")
        XCTAssertFalse(state.isTwoFACodeOrHardwareKeyVerified)
        XCTAssertFalse(state.isAccountLocked)
    }

    func test_did_appear_should_set_wallet_info_and_session_token() {
        let mockWalletInfo = MockDeviceVerificationService.mockWalletInfo
        testStore.assert(
            .send(.didAppear(context: .walletInfo(mockWalletInfo))) { state in
                state.emailAddress = mockWalletInfo.email
                state.walletGuid = mockWalletInfo.guid
                state.emailCode = mockWalletInfo.emailCode
            },
            .receive(.walletPairing(.setupSessionToken)),
            .do { self.mockMainQueue.advance() },
            .receive(.none)
        )
    }

    // MARK: - Wallet Pairing Actions

    func test_authenticate_success_should_update_view_state_and_decrypt_password() {
        /*
         Use Case: Authentication flow without any 2FA
         1. Setup walletInfo and sessionToken
         2. Reset error states (account locked or password error, for any previous errors)
         3. Decrypt wallet with the password from user
         */

        // some preliminery actions
        setupWalletInfoAndSessionToken()

        testStore.assert(
            // authentication without 2FA
            .send(.walletPairing(.authenticate)) { state in
                state.isLoading = true
            },
            .receive(.accountLockedErrorVisibility(false)) { state in
                state.isAccountLocked = false
            },
            .receive(.password(.incorrectPasswordErrorVisibility(false))) { state in
                state.passwordState.isPasswordIncorrect = false
            },
            .do { self.mockMainQueue.advance() },
            .receive(.walletPairing(.decryptWalletWithPassword(""))) { state in
                state.isLoading = true
            }
        )
    }

    func test_authenticate_email_required_should_return_relevant_actions() {
        /*
         Use Case: Authentication flow with auto-authorized email approval
         1. Setup walletInfo and sessionToken
         2. Reset error states (account locked or password error, for any previous errors)
         3. When authenticate request sent, received an error saying email authorization required
         4. Auto-approve email authorization, the 2FA type will be set to standard
         5. Conduct polling every 2 seconds, check if GUID has been set remotely
         6. Authenticate again, clear error states again, and proceed to wallet decryption with pw
         */

        // set email authorization as default twoFA type
        (testStore.environment.loginService as! MockLoginService).twoFAType = .email

        // some preliminery actions
        setupWalletInfoAndSessionToken()

        testStore.assert(
            // authentication
            .send(.walletPairing(.authenticate)) { state in
                state.isLoading = true
            },
            .receive(.accountLockedErrorVisibility(false)) { state in
                state.isAccountLocked = false
            },
            .receive(.password(.incorrectPasswordErrorVisibility(false))) { state in
                state.passwordState.isPasswordIncorrect = false
            },
            .do { self.mockMainQueue.advance() },

            // authentication with email required
            .receive(.walletPairing(.approveEmailAuthorization)),
            .receive(.none),
            .do { self.mockMainQueue.advance() },
            .environment { environment in
                // after approval twoFA type should be set to standard
                (environment.loginService as! MockLoginService).twoFAType = .standard
            },
            .do {
                // nothing should happen after 1 second
                self.mockPollingQueue.advance(by: 1)
            },
            .do {
                // polling should happen after 1 more second (2 seconds in total)
                self.mockPollingQueue.advance(by: 1)
            },
            .receive(.walletPairing(.pollWalletIdentifier)),
            .do { self.mockMainQueue.advance() },
            .receive(.walletPairing(.authenticate)) { state in
                state.isLoading = true
            },
            .receive(.accountLockedErrorVisibility(false)) { state in
                state.isAccountLocked = false
            },
            .receive(.password(.incorrectPasswordErrorVisibility(false))) { state in
                state.passwordState.isPasswordIncorrect = false
            },
            .receive(.walletPairing(.decryptWalletWithPassword(""))) { state in
                state.isLoading = true
            },
            .do { self.mockMainQueue.advance() }
        )
    }

    func test_authenticate_sms_required_should_return_relevant_actions() {
        /*
         Use Case: Authentication flow with SMS as 2FA
         1. Setup walletInfo and sessionToken
         2. Reset error states (account locked or password error, for any previous errors)
         3. When authenticate request sent, received an error saying SMS required
         4. Request an SMS code for user
         5. Show the resend SMS button and 2FA field
         */

        // set sms as default twoFA type
        (testStore.environment.loginService as! MockLoginService).twoFAType = .sms

        // some preliminery actions
        setupWalletInfoAndSessionToken()

        testStore.assert(
            // authentication
            .send(.walletPairing(.authenticate)) { state in
                state.isLoading = true
            },
            .receive(.accountLockedErrorVisibility(false)) { state in
                state.isAccountLocked = false
            },
            .receive(.password(.incorrectPasswordErrorVisibility(false))) { state in
                state.passwordState.isPasswordIncorrect = false
            },
            .do { self.mockMainQueue.advance() },

            // authentication with sms requied
            .receive(.walletPairing(.requestSMSCode)),
            .receive(.twoFA(.resendSMSButtonVisibility(true))) { state in
                state.twoFAState?.isResendSMSButtonVisible = true
            },
            .receive(.twoFA(.twoFACodeFieldVisibility(true))) { state in
                state.twoFAState?.isTwoFACodeFieldVisible = true
                state.isLoading = false
            },
            .receive(.none),
            .do { self.mockMainQueue.advance() }
        )
    }

    func test_authenticate_google_auth_required_should_return_relevant_actions() {
        /*
         Use Case: Authentication flow with google authenticator as 2FA
         1. Setup walletInfo and sessionToken
         2. Reset error states (account locked or password error, for any previous errors)
         3. When authenticate request sent, received an error saying google authenticator required
         4. Show the 2FA Field
         */

        // set google auth as default twoFA type
        (testStore.environment.loginService as! MockLoginService).twoFAType = .google

        // some preliminery actions
        setupWalletInfoAndSessionToken()

        testStore.assert(
            // authentication
            .send(.walletPairing(.authenticate)) { state in
                state.isLoading = true
            },
            .receive(.accountLockedErrorVisibility(false)) { state in
                state.isAccountLocked = false
            },
            .receive(.password(.incorrectPasswordErrorVisibility(false))) { state in
                state.passwordState.isPasswordIncorrect = false
            },
            .do { self.mockMainQueue.advance() },

            // authentication with google auth required
            .receive(.twoFA(.twoFACodeFieldVisibility(true))) { state in
                state.twoFAState?.isTwoFACodeFieldVisible = true
                state.isLoading = false
            }
        )
    }

    func test_authenticate_hardware_key_required_should_return_relevant_actions() {
        /*
         Use Case: Authentication flow with hardware key as 2FA
         1. Setup walletInfo and sessionToken
         2. Reset error states (account locked or password error, for any previous errors)
         3. When authenticate request sent, received an error saying yubikey required
         4. Show the Hardware Key Field
         */

        // set yubikey as default twoFA type
        (testStore.environment.loginService as! MockLoginService).twoFAType = .yubiKey

        // some preliminery actions
        setupWalletInfoAndSessionToken()

        testStore.assert(
            // authentication
            .send(.walletPairing(.authenticate)) { state in
                state.isLoading = true
            },
            .receive(.accountLockedErrorVisibility(false)) { state in
                state.isAccountLocked = false
            },
            .receive(.password(.incorrectPasswordErrorVisibility(false))) { state in
                state.passwordState.isPasswordIncorrect = false
            },
            .do { self.mockMainQueue.advance() },

            // authentication with yubikey required
            .receive(.hardwareKey(.hardwareKeyCodeFieldVisibility(true))) { state in
                state.hardwareKeyState?.isHardwareKeyCodeFieldVisible = true
                state.isLoading = false
            }
        )
    }

    func test_authenticate_with_twoFA_should_return_relevant_actions() {
        /*
         Use Case: Authentication flow with SMS as 2FA
         1. Assuming twoFA field/Hardware Key field has been set visible
         2. Setup walletInfo and session token
         3. Reset error states
         4. Authenticate with 2FA, clear 2FA error states
         5. Set 2FA verified on success
         6. Proceed to wallet decryption with password
         */

        // set 2FA required (e.g. sms)
        (testStore.environment.loginService as! MockLoginService).twoFAType = .sms

        // some preliminery actions
        setupWalletInfoAndSessionToken()

        testStore.assert(
            // set twoFA field visible
            .send(.twoFA(.twoFACodeFieldVisibility(true))) { state in
                state.twoFAState?.isTwoFACodeFieldVisible = true
            },
            // authentication
            .send(.walletPairing(.authenticate)) { state in
                state.isLoading = true
            },
            .receive(.accountLockedErrorVisibility(false)) { state in
                state.isAccountLocked = false
            },
            .receive(.password(.incorrectPasswordErrorVisibility(false))) { state in
                state.passwordState.isPasswordIncorrect = false
            },
            .do { self.mockMainQueue.advance() },

            // authentication using 2FA
            .receive(.walletPairing(.authenticateWithTwoFAOrHardwareKey)),
            .receive(.hardwareKey(.incorrectHardwareKeyCodeErrorVisibility(false))) { state in
                state.hardwareKeyState?.isHardwareKeyCodeIncorrect = false
            },
            .receive(.twoFA(.incorrectTwoFACodeErrorVisibility(false))) { state in
                state.twoFAState?.isTwoFACodeIncorrect = false
            },
            .receive(.setTwoFAOrHardwareKeyVerified(true)) { state in
                state.isTwoFACodeOrHardwareKeyVerified = true
                state.isLoading = false
            },
            .receive(.walletPairing(.decryptWalletWithPassword(""))) { state in
                state.isLoading = true
            }
        )
    }

    func test_authenticate_with_twoFA_wrong_code_error() {
        // set 2FA required (e.g. sms)
        (testStore.environment.loginService as! MockLoginService).twoFAType = .sms

        // set 2FA error type
        let mockAttemptsLeft = 4
        (testStore.environment.loginService as! MockLoginService)
            .twoFAServiceError = .twoFAWalletServiceError(.wrongCode(attemptsLeft: mockAttemptsLeft))

        // some preliminery actions
        setupWalletInfoAndSessionToken()

        testStore.assert(
            .send(.walletPairing(.authenticateWithTwoFAOrHardwareKey)) { state in
                state.isLoading = true
            },
            .receive(.hardwareKey(.incorrectHardwareKeyCodeErrorVisibility(false))) { state in
                state.hardwareKeyState?.isHardwareKeyCodeIncorrect = false
            },
            .receive(.twoFA(.incorrectTwoFACodeErrorVisibility(false))) { state in
                state.twoFAState?.isTwoFACodeIncorrect = false
            },
            .do { self.mockMainQueue.advance() },
            .receive(.twoFA(.didChangeTwoFACodeAttemptsLeft(mockAttemptsLeft))) { state in
                state.twoFAState?.twoFACodeAttemptsLeft = mockAttemptsLeft
            },
            .receive(.twoFA(.incorrectTwoFACodeErrorVisibility(true))) { state in
                state.twoFAState?.isTwoFACodeIncorrect = true
                state.isLoading = false
            }
        )
    }

    // MARK: - Helpers

    private func setupWalletInfoAndSessionToken() {
        let mockWalletInfo = MockDeviceVerificationService.mockWalletInfo
        testStore.assert(
            .send(.didAppear(context: .walletInfo(mockWalletInfo))) { state in
                state.emailAddress = mockWalletInfo.email
                state.walletGuid = mockWalletInfo.guid
                state.emailCode = mockWalletInfo.emailCode
            },
            .receive(.walletPairing(.setupSessionToken)),
            .do { self.mockMainQueue.advance() },
            .receive(.none)
        )
    }
}