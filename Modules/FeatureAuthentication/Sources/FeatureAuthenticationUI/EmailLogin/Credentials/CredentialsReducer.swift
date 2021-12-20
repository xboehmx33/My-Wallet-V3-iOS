// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import ComposableArchitecture
import DIKit
import FeatureAuthenticationDomain
import Localization
import ToolKit

// MARK: - Type

public enum CredentialsAction: Equatable {
    public enum AlertAction: Equatable {
        case show(title: String, message: String)
        case dismiss
    }

    case alert(AlertAction)
    case closeButtonTapped
    case continueButtonTapped
    case didAppear(context: CredentialsContext)
    case didChangeWalletIdentifier(String)
    case walletPairing(WalletPairingAction)
    case password(PasswordAction)
    case twoFA(TwoFAAction)
    case hardwareKey(HardwareKeyAction)
    case seedPhrase(SeedPhraseAction)
    case setTroubleLoggingInScreenVisible(Bool)
    case showAccountLockedError(Bool)
    case openExternalLink(URL)
    case none
}

public enum CredentialsContext: Equatable {
    case walletInfo(WalletInfo)
    /// pre-fill guid if present (from the deeplink)
    case walletIdentifier(guid: String?)
    case manualPairing
    case none
}

private typealias CredentialsLocalization = LocalizationConstants.FeatureAuthentication.EmailLogin

// MARK: - Properties

public struct CredentialsState: Equatable {
    var walletPairingState: WalletPairingState
    var passwordState: PasswordState
    var twoFAState: TwoFAState?
    var hardwareKeyState: HardwareKeyState?
    var seedPhraseState: SeedPhraseState?
    var nabuInfo: WalletInfo.NabuInfo?
    var isManualPairing: Bool
    var isTroubleLoggingInScreenVisible: Bool
    var isTwoFactorOTPVerified: Bool
    var isWalletIdentifierIncorrect: Bool
    var isAccountLocked: Bool
    var credentialsFailureAlert: AlertState<CredentialsAction>?
    var isLoading: Bool

    init(
        walletPairingState: WalletPairingState = .init(),
        passwordState: PasswordState = .init(),
        twoFAState: TwoFAState? = nil,
        hardwareKeyState: HardwareKeyState? = nil,
        seedPhraseState: SeedPhraseState? = nil,
        nabuInfo: WalletInfo.NabuInfo? = nil,
        isManualPairing: Bool = false,
        isTroubleLoggingInScreenVisible: Bool = false,
        isTwoFactorOTPVerified: Bool = false,
        isWalletIdentifierIncorrect: Bool = false,
        isAccountLocked: Bool = false,
        credentialsFailureAlert: AlertState<CredentialsAction>? = nil,
        isLoading: Bool = false
    ) {
        self.walletPairingState = walletPairingState
        self.passwordState = passwordState
        self.twoFAState = twoFAState
        self.hardwareKeyState = hardwareKeyState
        self.seedPhraseState = seedPhraseState
        self.nabuInfo = nabuInfo
        self.isManualPairing = isManualPairing
        self.isTroubleLoggingInScreenVisible = isTroubleLoggingInScreenVisible
        self.isTwoFactorOTPVerified = isTwoFactorOTPVerified
        self.isWalletIdentifierIncorrect = isWalletIdentifierIncorrect
        self.isAccountLocked = isAccountLocked
        self.credentialsFailureAlert = credentialsFailureAlert
        self.isLoading = isLoading
    }
}

struct CredentialsEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let pollingQueue: AnySchedulerOf<DispatchQueue>
    let sessionTokenService: SessionTokenServiceAPI
    let deviceVerificationService: DeviceVerificationServiceAPI
    let emailAuthorizationService: EmailAuthorizationServiceAPI
    let smsService: SMSServiceAPI
    let loginService: LoginServiceAPI
    let analyticsRecorder: AnalyticsEventRecorderAPI
    let externalAppOpener: ExternalAppOpener
    let featureFlagsService: FeatureFlagsServiceAPI
    let errorRecorder: ErrorRecording
    let walletIdentifierValidator: (String) -> Bool

    init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        pollingQueue: AnySchedulerOf<DispatchQueue> = DispatchQueue(
            label: "com.blockchain.CredentialsEnvironmentPollingQueue",
            qos: .utility
        ).eraseToAnyScheduler(),
        sessionTokenService: SessionTokenServiceAPI = resolve(),
        deviceVerificationService: DeviceVerificationServiceAPI,
        emailAuthorizationService: EmailAuthorizationServiceAPI = resolve(),
        smsService: SMSServiceAPI = resolve(),
        loginService: LoginServiceAPI = resolve(),
        errorRecorder: ErrorRecording,
        externalAppOpener: ExternalAppOpener = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI,
        analyticsRecorder: AnalyticsEventRecorderAPI,
        walletIdentifierValidator: @escaping (String) -> Bool = TextValidation.walletIdentifierValidator
    ) {
        self.mainQueue = mainQueue
        self.pollingQueue = pollingQueue
        self.sessionTokenService = sessionTokenService
        self.deviceVerificationService = deviceVerificationService
        self.emailAuthorizationService = emailAuthorizationService
        self.smsService = smsService
        self.loginService = loginService
        self.errorRecorder = errorRecorder
        self.externalAppOpener = externalAppOpener
        self.featureFlagsService = featureFlagsService
        self.analyticsRecorder = analyticsRecorder
        self.walletIdentifierValidator = walletIdentifierValidator
    }
}

let credentialsReducer = Reducer.combine(
    passwordReducer
        .pullback(
            state: \CredentialsState.passwordState,
            action: /CredentialsAction.password,
            environment: { _ in PasswordEnvironment() }
        ),
    twoFAReducer
        .optional()
        .pullback(
            state: \CredentialsState.twoFAState,
            action: /CredentialsAction.twoFA,
            environment: { $0 }
        ),
    hardwareKeyReducer
        .optional()
        .pullback(
            state: \CredentialsState.hardwareKeyState,
            action: /CredentialsAction.hardwareKey,
            environment: { $0 }
        ),
    walletPairingReducer
        .pullback(
            state: \CredentialsState.walletPairingState,
            action: /CredentialsAction.walletPairing,
            environment: {
                WalletPairingEnvironment(
                    mainQueue: $0.mainQueue,
                    pollingQueue: $0.pollingQueue,
                    sessionTokenService: $0.sessionTokenService,
                    deviceVerificationService: $0.deviceVerificationService,
                    emailAuthorizationService: $0.emailAuthorizationService,
                    smsService: $0.smsService,
                    loginService: $0.loginService,
                    errorRecorder: $0.errorRecorder
                )
            }
        ),
    seedPhraseReducer
        .optional()
        .pullback(
            state: \CredentialsState.seedPhraseState,
            action: /CredentialsAction.seedPhrase,
            environment: {
                SeedPhraseEnvironment(
                    mainQueue: $0.mainQueue,
                    externalAppOpener: $0.externalAppOpener,
                    analyticsRecorder: $0.analyticsRecorder
                )
            }
        ),
    Reducer<
        CredentialsState,
        CredentialsAction,
        CredentialsEnvironment
            // swiftlint:disable closure_body_length
    > { state, action, environment in
        switch action {
        case .alert(.show(let title, let message)):
            state.isLoading = false
            state.credentialsFailureAlert = AlertState(
                title: TextState(verbatim: title),
                message: TextState(verbatim: message),
                dismissButton: .default(
                    TextState(LocalizationConstants.okString),
                    action: .send(.alert(.dismiss))
                )
            )
            return .none

        case .alert(.dismiss):
            state.credentialsFailureAlert = nil
            return .none

        case .closeButtonTapped:
            return .cancel(id: WalletPairingCancelations.WalletIdentifierPollingTimerId())

        case .didAppear(.walletInfo(let info)):
            state.walletPairingState.emailAddress = info.email ?? ""
            state.walletPairingState.walletGuid = info.guid
            state.walletPairingState.emailCode = info.emailCode
            if let nabuInfo = info.nabuInfo {
                state.nabuInfo = nabuInfo
            }
            if let type = info.twoFAType, type.isTwoFactor {
                // authenticate with empty password to set GUID and send SMS if needed
                return Effect(value: .walletPairing(.authenticate("")))
            }
            return .none

        case .didAppear(.walletIdentifier(let guid)):
            state.walletPairingState.walletGuid = guid ?? ""
            return .none

        case .didAppear(.manualPairing):
            state.walletPairingState.emailAddress = "not available on manual pairing"
            state.isManualPairing = true
            return Effect(value: .walletPairing(.setupSessionToken))

        case .didAppear:
            return .none

        case .didChangeWalletIdentifier(let guid):
            state.walletPairingState.walletGuid = guid
            guard !guid.isEmpty else {
                state.isWalletIdentifierIncorrect = false
                return .none
            }
            state.isWalletIdentifierIncorrect = !environment.walletIdentifierValidator(guid)
            return .none

        case .continueButtonTapped:
            if let twoFAState = state.twoFAState,
               twoFAState.isTwoFACodeFieldVisible
            {
                return Effect(
                    value: .walletPairing(.authenticateWithTwoFactorOTP(twoFAState.twoFACode))
                )
            } else if let hardwareKeyState = state.hardwareKeyState,
                      hardwareKeyState.isHardwareKeyCodeFieldVisible
            {
                return Effect(
                    value: .walletPairing(.authenticateWithTwoFactorOTP(hardwareKeyState.hardwareKeyCode))
                )
            }
            return Effect(value: .walletPairing(.authenticate(state.passwordState.password)))

        case .walletPairing(.authenticate):
            // Set loading state
            state.isLoading = true
            return clearErrorStates(state)

        case .walletPairing(.authenticateDidFail(let error)):
            return authenticateDidFail(error, &state, environment)

        case .walletPairing(.authenticateWithTwoFactorOTP):
            // Set loading state
            state.isLoading = true
            return clearErrorStates(state)

        case .walletPairing(.authenticateWithTwoFactorOTPDidFail(let error)):
            return authenticateWithTwoFactorOTPDidFail(error, environment)

        case .walletPairing(.decryptWalletWithPassword):
            // also handled in welcome reducer
            state.isLoading = true
            return .none

        case .walletPairing(.didResendSMSCode(let result)):
            return didResendSMSCode(result, environment)

        case .walletPairing(.didSetupSessionToken(let result)):
            return didSetupSessionToken(result, environment)

        case .walletPairing(.handleSMS):
            return handleSMS()

        case .walletPairing(.needsEmailAuthorization):
            // display authorization required alert
            return needsEmailAuthorization()

        case .walletPairing(.twoFactorOTPDidVerified):
            state.isTwoFactorOTPVerified = true
            state.isLoading = false
            let password = state.passwordState.password
            return Effect(value: .walletPairing(.decryptWalletWithPassword(password)))

        case .walletPairing(.approveEmailAuthorization),
             .walletPairing(.pollWalletIdentifier),
             .walletPairing(.resendSMSCode),
             .walletPairing(.setupSessionToken),
             .walletPairing(.startPolling),
             .walletPairing(.none):
            // handled in wallet pairing reducer
            return .none

        case .showAccountLockedError(let shouldShow):
            state.isAccountLocked = shouldShow
            state.isLoading = shouldShow ? false : state.isLoading
            return .none

        case .openExternalLink(let url):
            environment.externalAppOpener.open(url)
            return .none

        case .twoFA(.showTwoFACodeField(let visible)):
            state.isLoading = visible ? false : state.isLoading
            return .none

        case .twoFA(.showIncorrectTwoFACodeError(let context)):
            state.isLoading = context.hasError ? false : state.isLoading
            return .none

        case .hardwareKey(.showHardwareKeyCodeField(let visible)),
             .hardwareKey(.showIncorrectHardwareKeyCodeError(let visible)):
            state.isLoading = visible ? false : state.isLoading
            return .none

        case .password(.showIncorrectPasswordError(true)):
            state.isLoading = false
            // reset state
            state.twoFAState = .init()
            state.hardwareKeyState = .init()
            return .none

        case .password(.showIncorrectPasswordError(false)):
            state.isLoading = true
            return .none

        case .setTroubleLoggingInScreenVisible(let isVisible):
            state.isTroubleLoggingInScreenVisible = isVisible
            if isVisible {
                state.seedPhraseState = .init(
                    context: .troubleLoggingIn,
                    emailAddress: state.walletPairingState.emailAddress,
                    nabuInfo: state.nabuInfo
                )
            }
            return .none

        case .twoFA,
             .hardwareKey,
             .password,
             .seedPhrase,
             .none:
            return .none
        }
    }
)
.analytics()

// MARK: - Private Methods

private func clearErrorStates(
    _ state: CredentialsState
) -> Effect<CredentialsAction, Never> {
    var effects: [Effect<CredentialsAction, Never>] = [
        Effect(value: .showAccountLockedError(false)),
        Effect(value: .password(.showIncorrectPasswordError(false)))
    ]
    if state.twoFAState != nil {
        effects.append(Effect(value: .twoFA(.showIncorrectTwoFACodeError(.none))))
    }
    if state.hardwareKeyState != nil {
        effects.append(Effect(value: .hardwareKey(.showIncorrectHardwareKeyCodeError(false))))
    }
    return .merge(effects)
}

private func authenticateDidFail(
    _ error: LoginServiceError,
    _ state: inout CredentialsState,
    _ environment: CredentialsEnvironment
) -> Effect<CredentialsAction, Never> {
    let isManualPairing = state.isManualPairing
    switch error {
    case .twoFactorOTPRequired(let type):
        switch type {
        case .email:
            switch isManualPairing {
            case true:
                return Effect(value: .walletPairing(.needsEmailAuthorization))
            case false:
                return Effect(value: .walletPairing(.approveEmailAuthorization))
            }
        case .sms:
            state.twoFAState = .init(
                twoFAType: .sms
            )
            return Effect(value: .walletPairing(.handleSMS))
        case .google:
            state.twoFAState = .init(
                twoFAType: .google
            )
            return Effect(value: .twoFA(.showTwoFACodeField(true)))
        case .yubiKey, .yubikeyMtGox:
            state.hardwareKeyState = .init()
            return Effect(value: .hardwareKey(.showHardwareKeyCodeField(true)))
        default:
            fatalError("Unsupported TwoFA Types")
        }
    case .walletPayloadServiceError(.accountLocked):
        return Effect(value: .showAccountLockedError(true))
    case .walletPayloadServiceError(let error):
        environment.errorRecorder.error(error)
        return Effect(
            value: .alert(
                .show(
                    title: CredentialsLocalization.Alerts.GenericNetworkError.title,
                    message: CredentialsLocalization.Alerts.GenericNetworkError.message
                )
            )
        )
    case .twoFAWalletServiceError:
        fatalError("Shouldn't receive TwoFAService errors here")
    }
}

private func authenticateWithTwoFactorOTPDidFail(
    _ error: LoginServiceError,
    _ environment: CredentialsEnvironment
) -> Effect<CredentialsAction, Never> {
    switch error {
    case .twoFAWalletServiceError(let error):
        switch error {
        case .wrongCode(let attemptsLeft):
            return Effect(value: .twoFA(.didChangeTwoFACodeAttemptsLeft(attemptsLeft)))
        case .accountLocked:
            return Effect(value: .showAccountLockedError(true))
        case .missingCode:
            return Effect(value: .twoFA(.showIncorrectTwoFACodeError(.missingCode)))
        case .missingPayload, .missingCredentials, .networkError:
            return Effect(
                value:
                .alert(
                    .show(
                        title: CredentialsLocalization.Alerts.GenericNetworkError.title,
                        message: CredentialsLocalization.Alerts.GenericNetworkError.message
                    )
                )
            )
        }
    case .walletPayloadServiceError:
        fatalError("Shouldn't receive WalletPayloadService errors here")
    case .twoFactorOTPRequired:
        fatalError("Shouldn't receive twoFactorOTPRequired error here")
    }
}

private func didResendSMSCode(
    _ result: Result<EmptyValue, SMSServiceError>,
    _ environment: CredentialsEnvironment
) -> Effect<CredentialsAction, Never> {
    switch result {
    case .success:
        return Effect(
            value: .alert(
                .show(
                    title: CredentialsLocalization.Alerts.SMSCode.Success.title,
                    message: CredentialsLocalization.Alerts.SMSCode.Success.message
                )
            )
        )
    case .failure(let error):
        environment.errorRecorder.error(error)
        return Effect(
            value: .alert(
                .show(
                    title: CredentialsLocalization.Alerts.SMSCode.Failure.title,
                    message: CredentialsLocalization.Alerts.SMSCode.Failure.message
                )
            )
        )
    }
}

private func didSetupSessionToken(
    _ result: Result<EmptyValue, SessionTokenServiceError>,
    _ environment: CredentialsEnvironment
) -> Effect<CredentialsAction, Never> {
    switch result {
    case .success:
        return .none
    case .failure(let error):
        environment.errorRecorder.error(error)
        return Effect(
            value: .alert(
                .show(
                    title: CredentialsLocalization.Alerts.GenericNetworkError.title,
                    message: CredentialsLocalization.Alerts.GenericNetworkError.message
                )
            )
        )
    }
}

private func handleSMS() -> Effect<CredentialsAction, Never> {
    .merge(
        Effect(value: .twoFA(.showResendSMSButton(true))),
        Effect(value: .twoFA(.showTwoFACodeField(true))),
        Effect(
            value: .alert(
                .show(
                    title: CredentialsLocalization.Alerts.SMSCode.Success.title,
                    message: CredentialsLocalization.Alerts.SMSCode.Success.message
                )
            )
        )
    )
}

private func needsEmailAuthorization() -> Effect<CredentialsAction, Never> {
    Effect(
        value: .alert(
            .show(
                title: CredentialsLocalization.Alerts.EmailAuthorizationAlert.title,
                message: CredentialsLocalization.Alerts.EmailAuthorizationAlert.message
            )
        )
    )
}

// MARK: - Extension

extension Reducer where
    Action == CredentialsAction,
    State == CredentialsState,
    Environment == CredentialsEnvironment
{
    /// Helper reducer for analytics tracking
    fileprivate func analytics() -> Self {
        combined(
            with: Reducer<
                CredentialsState,
                CredentialsAction,
                CredentialsEnvironment
            > { _, action, environment in
                switch action {
                case .continueButtonTapped:
                    environment.analyticsRecorder.record(
                        event: .loginPasswordEntered
                    )
                    return .none
                case .walletPairing(.authenticateWithTwoFactorOTP):
                    environment.analyticsRecorder.record(
                        event: .loginTwoStepVerificationEntered
                    )
                    return .none
                case .twoFA(.didChangeTwoFACodeAttemptsLeft):
                    environment.analyticsRecorder.record(
                        event: .loginTwoStepVerificationDenied
                    )
                    return .none
                case .setTroubleLoggingInScreenVisible(true):
                    environment.analyticsRecorder.record(
                        event: .recoveryOptionSelected
                    )
                    return .none
                default:
                    return .none
                }
            }
        )
    }
}
