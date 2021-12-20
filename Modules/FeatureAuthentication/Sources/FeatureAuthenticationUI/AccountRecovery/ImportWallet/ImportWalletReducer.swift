// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import ComposableArchitecture
import FeatureAuthenticationDomain
import ToolKit

public enum ImportWalletAction: Equatable {
    case importWalletButtonTapped
    case goBackButtonTapped
    case setCreateAccountScreenVisible(Bool)
    case createAccount(CreateAccountAction)
}

struct ImportWalletState: Equatable {
    var createAccountState: CreateAccountState?
    var isCreateAccountScreenVisible: Bool

    init() {
        isCreateAccountScreenVisible = false
    }
}

struct ImportWalletEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let passwordValidator: PasswordValidatorAPI
    let externalAppOpener: ExternalAppOpener
    let analyticsRecorder: AnalyticsEventRecorderAPI
}

let importWalletReducer = Reducer.combine(
    createAccountReducer
        .optional()
        .pullback(
            state: \.createAccountState,
            action: /ImportWalletAction.createAccount,
            environment: {
                CreateAccountEnvironment(
                    mainQueue: $0.mainQueue,
                    passwordValidator: $0.passwordValidator,
                    externalAppOpener: $0.externalAppOpener,
                    analyticsRecorder: $0.analyticsRecorder
                )
            }
        ),
    Reducer<
        ImportWalletState,
        ImportWalletAction,
        ImportWalletEnvironment
    > { state, action, environment in
        switch action {
        case .setCreateAccountScreenVisible(let isVisible):
            state.isCreateAccountScreenVisible = isVisible
            if isVisible {
                state.createAccountState = .init(
                    context: .importWallet
                )
            }
            return .none
        case .importWalletButtonTapped:
            environment.analyticsRecorder.record(
                event: .importWalletClicked
            )
            return Effect(value: .setCreateAccountScreenVisible(true))
        case .goBackButtonTapped:
            environment.analyticsRecorder.record(
                event: .importWalletCancelled
            )
            return .none
        case .createAccount:
            return .none
        }
    }
)
