// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import ComposableArchitecture
import DIKit
import FeatureAuthenticationDomain
import ToolKit

// MARK: - Type

public enum SeedPhraseAction: Equatable {

    public enum URLContent {

        case contactSupport

        var url: URL? {
            switch self {
            case .contactSupport:
                return URL(string: Constants.SupportURL.ResetAccount.contactSupport)
            }
        }
    }

    case closeButtonTapped
    case didChangeSeedPhrase(String)
    case didChangeSeedPhraseScore(MnemonicValidationScore)
    case validateSeedPhrase
    case setResetPasswordScreenVisible(Bool)
    case setResetAccountBottomSheetVisible(Bool)
    case setLostFundsWarningScreenVisible(Bool)
    case setImportWalletScreenVisible(Bool)
    case resetPassword(ResetPasswordAction)
    case resetAccountWarning(ResetAccountWarningAction)
    case lostFundsWarning(LostFundsWarningAction)
    case importWallet(ImportWalletAction)
    case restoreWallet(WalletRecovery)
    case open(urlContent: URLContent)
    case none
}

public enum AccountRecoveryContext: Equatable {
    case troubleLoggingIn
    case restoreWallet
    case none
}

// MARK: - Properties

public struct SeedPhraseState: Equatable {
    var context: AccountRecoveryContext
    var emailAddress: String
    var nabuInfo: WalletInfo.NabuInfo?
    var seedPhrase: String
    var seedPhraseScore: MnemonicValidationScore
    var isResetPasswordScreenVisible: Bool
    var isResetAccountBottomSheetVisible: Bool
    var isLostFundsWarningScreenVisible: Bool
    var isImportWalletScreenVisible: Bool
    var resetPasswordState: ResetPasswordState?
    var resetAccountWarningState: ResetAccountWarningState?
    var lostFundsWarningState: LostFundsWarningState?
    var importWalletState: ImportWalletState?

    var accountResettable: Bool {
        nabuInfo != nil
    }

    init(context: AccountRecoveryContext, emailAddress: String = "", nabuInfo: WalletInfo.NabuInfo? = nil) {
        self.context = context
        self.emailAddress = emailAddress
        self.nabuInfo = nabuInfo
        seedPhrase = ""
        seedPhraseScore = .none
        isResetPasswordScreenVisible = false
        isResetAccountBottomSheetVisible = false
        isLostFundsWarningScreenVisible = false
        isImportWalletScreenVisible = false
    }
}

struct SeedPhraseEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let validator: SeedPhraseValidatorAPI
    let externalAppOpener: ExternalAppOpener
    let passwordValidator: PasswordValidatorAPI
    let analyticsRecorder: AnalyticsEventRecorderAPI

    init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        validator: SeedPhraseValidatorAPI = resolve(),
        passwordValidator: PasswordValidatorAPI = resolve(),
        externalAppOpener: ExternalAppOpener,
        analyticsRecorder: AnalyticsEventRecorderAPI
    ) {
        self.mainQueue = mainQueue
        self.validator = validator
        self.passwordValidator = passwordValidator
        self.externalAppOpener = externalAppOpener
        self.analyticsRecorder = analyticsRecorder
    }
}

let seedPhraseReducer = Reducer.combine(
    importWalletReducer
        .optional()
        .pullback(
            state: \SeedPhraseState.importWalletState,
            action: /SeedPhraseAction.importWallet,
            environment: {
                ImportWalletEnvironment(
                    mainQueue: $0.mainQueue,
                    passwordValidator: $0.passwordValidator,
                    externalAppOpener: $0.externalAppOpener,
                    analyticsRecorder: $0.analyticsRecorder
                )
            }
        ),
    resetAccountWarningReducer
        .optional()
        .pullback(
            state: \SeedPhraseState.resetAccountWarningState,
            action: /SeedPhraseAction.resetAccountWarning,
            environment: {
                ResetAccountWarningEnvironment(
                    analyticsRecorder: $0.analyticsRecorder
                )
            }
        ),
    lostFundsWarningReducer
        .optional()
        .pullback(
            state: \SeedPhraseState.lostFundsWarningState,
            action: /SeedPhraseAction.lostFundsWarning,
            environment: {
                LostFundsWarningEnvironment(
                    mainQueue: $0.mainQueue,
                    analyticsRecorder: $0.analyticsRecorder
                )
            }
        ),
    resetPasswordReducer
        .optional()
        .pullback(
            state: \SeedPhraseState.resetPasswordState,
            action: /SeedPhraseAction.resetPassword,
            environment: {
                ResetPasswordEnvironment(
                    mainQueue: $0.mainQueue
                )
            }
        ),
    Reducer<
        SeedPhraseState,
        SeedPhraseAction,
        SeedPhraseEnvironment
    > { state, action, environment in
        switch action {

        case .closeButtonTapped:
            return .none

        case .didChangeSeedPhrase(let seedPhrase):
            state.seedPhrase = seedPhrase
            return Effect(value: .validateSeedPhrase)

        case .didChangeSeedPhraseScore(let score):
            state.seedPhraseScore = score
            return .none

        case .validateSeedPhrase:
            return environment
                .validator
                .validate(phrase: state.seedPhrase)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map { result -> SeedPhraseAction in
                    guard case .success(let score) = result else {
                        return .none
                    }
                    return .didChangeSeedPhraseScore(score)
                }

        case .setResetPasswordScreenVisible(let isVisible):
            state.isResetPasswordScreenVisible = isVisible
            if isVisible {
                state.resetPasswordState = .init()
            }
            return .none

        case .setResetAccountBottomSheetVisible(let isVisible):
            state.isResetAccountBottomSheetVisible = isVisible
            if isVisible {
                state.resetAccountWarningState = .init()
            }
            return .none

        case .setLostFundsWarningScreenVisible(let isVisible):
            state.isLostFundsWarningScreenVisible = isVisible
            if isVisible {
                state.lostFundsWarningState = .init()
            }
            return .none

        case .setImportWalletScreenVisible(let isVisible):
            state.isImportWalletScreenVisible = isVisible
            if isVisible {
                state.importWalletState = .init()
            }
            return .none

        case .resetPassword:
            // handled in reset password reducer
            return .none

        case .resetAccountWarning(.retryButtonTapped),
             .resetAccountWarning(.onDisappear):
            return Effect(value: .setResetAccountBottomSheetVisible(false))

        case .resetAccountWarning(.continueResetButtonTapped):
            return .concatenate(
                Effect(value: .setResetAccountBottomSheetVisible(false)),
                Effect(value: .setLostFundsWarningScreenVisible(true))
            )

        case .lostFundsWarning(.goBackButtonTapped):
            return Effect(value: .setLostFundsWarningScreenVisible(false))

        case .lostFundsWarning(.resetPassword(.reset(let password))):
            guard let nabuInfo = state.nabuInfo else {
                return .none
            }
            return Effect(
                value: .restoreWallet(
                    .resetAccountRecovery(
                        email: state.emailAddress,
                        newPassword: password,
                        nabuInfo: nabuInfo
                    )
                )
            )

        case .lostFundsWarning:
            return .none

        case .importWallet(.goBackButtonTapped):
            return Effect(value: .setImportWalletScreenVisible(false))

        case .importWallet(.importWalletButtonTapped):
            return .none

        case .importWallet(.createAccount(.createAccount)):
            guard let createAccountState = state.importWalletState?.createAccountState else {
                return .none
            }
            return Effect(
                value: .restoreWallet(
                    .importRecovery(
                        email: createAccountState.emailAddress,
                        newPassword: createAccountState.password,
                        seedPhrase: state.seedPhrase
                    )
                )
            )

        case .importWallet:
            return .none

        case .restoreWallet:
            return .none

        case .open(let urlContent):
            guard let url = urlContent.url else {
                return .none
            }
            environment.externalAppOpener.open(url)
            return .none

        case .none:
            return .none
        }
    }
)
.analytics()

// MARK: - Extension

extension Reducer where
    Action == SeedPhraseAction,
    State == SeedPhraseState,
    Environment == SeedPhraseEnvironment
{
    /// Helper reducer for analytics tracking
    fileprivate func analytics() -> Self {
        combined(
            with: Reducer<
                SeedPhraseState,
                SeedPhraseAction,
                SeedPhraseEnvironment
            > { _, action, environment in
                switch action {
                case .setResetPasswordScreenVisible(true):
                    environment.analyticsRecorder.record(
                        event: .recoveryPhraseEntered
                    )
                    return .none
                case .setImportWalletScreenVisible(true):
                    environment.analyticsRecorder.record(
                        event: .recoveryPhraseEntered
                    )
                    return .none
                case .setResetAccountBottomSheetVisible(true):
                    environment.analyticsRecorder.record(
                        event: .resetAccountClicked
                    )
                    return .none
                case .setResetAccountBottomSheetVisible(false):
                    environment.analyticsRecorder.record(
                        event: .resetAccountCancelled
                    )
                    return .none
                case .setLostFundsWarningScreenVisible(true):
                    environment.analyticsRecorder.record(
                        event: .resetAccountCancelled
                    )
                    return .none
                default:
                    return .none
                }
            }
        )
    }
}
