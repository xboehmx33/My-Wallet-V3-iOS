// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import ComposableArchitecture
import ComposableNavigation
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import UIComponentsKit

private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.CreateAccount

struct CreateAccountView: View {

    private let store: Store<CreateAccountState, CreateAccountAction>
    @ObservedObject private var viewStore: ViewStore<CreateAccountState, CreateAccountAction>

    init(store: Store<CreateAccountState, CreateAccountAction>) {
        self.store = store
        viewStore = ViewStore(store)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.padding3) {
                    CreateAccountHeader()
                    CreateAccountForm(viewStore: viewStore)
                    Spacer()
                    ComponentLibrary.PrimaryButton(
                        title: LocalizedString.createAccountButton,
                        isLoading: viewStore.validatingInput
                    ) {
                        viewStore.send(.createButtonTapped)
                    }
                    .disabled(viewStore.validatingInput || viewStore.inputValidationState.isInvalid)
                    .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.createAccountButton)
                }
                .padding(Spacing.padding3)
            }
            // setting the frame is necessary for the Spacer inside the VStack above to work properly
            .frame(height: geometry.size.height)
        }
        .primaryNavigation(title: "") {
            Button {
                viewStore.send(.createButtonTapped)
            } label: {
                Text(LocalizedString.nextButton)
                    .typography(.paragraph2)
                    .foregroundColor(.semantic.primary)
            }
            .disabled(viewStore.validatingInput || viewStore.inputValidationState.isInvalid)
            .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.nextButton)
        }
        .onWillDisappear {
            viewStore.send(.onWillDisappear)
        }
        .navigationRoute(in: store)
    }
}

private struct CreateAccountHeader: View {

    var body: some View {
        VStack(spacing: Spacing.padding3) {
            Icon.globe
                .frame(width: 32, height: 32)
                .accentColor(.semantic.primary)
            VStack(spacing: Spacing.baseline) {
                Text(LocalizedString.headerTitle)
                    .typography(.title2)
                Text(LocalizedString.headerSubtitle)
                    .typography(.paragraph1)
            }
        }
    }
}

private struct CreateAccountForm: View {

    @ObservedObject var viewStore: ViewStore<CreateAccountState, CreateAccountAction>

    var body: some View {
        VStack(spacing: Spacing.padding2) {
            emailField
            passwordField
            countryAndStatePickers
            termsAgreementView
        }
    }

    private var emailField: some View {
        let shouldShowError = viewStore.inputValidationState == .invalid(.invalidEmail)
        return Input(
            text: viewStore.binding(\.$emailAddress),
            isFirstResponder: viewStore
                .binding(\.$selectedInputField)
                .equals(.email),
            label: LocalizedString.TextFieldTitle.email,
            subText: shouldShowError ? LocalizedString.TextFieldError.invalidEmail : nil,
            subTextStyle: .error,
            placeholder: LocalizedString.TextFieldPlaceholder.email,
            state: shouldShowError ? .error : .default,
            configuration: {
                $0.autocapitalizationType = .none
                $0.keyboardType = .emailAddress
                $0.textContentType = .emailAddress
            },
            onReturnTapped: {
                viewStore.send(.set(\.$selectedInputField, .password))
            }
        )
        .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.emailGroup)
    }

    private var passwordField: some View {
        let shouldShowError = viewStore.inputValidationState == .invalid(.weakPassword)
        return Input(
            text: viewStore.binding(\.$password),
            isFirstResponder: viewStore
                .binding(\.$selectedInputField)
                .equals(.password),
            label: LocalizedString.TextFieldTitle.password,
            subText: viewStore.passwordStrength.displayString,
            subTextStyle: viewStore.passwordStrength.inputSubTextStyle,
            state: shouldShowError ? .error : .default,
            configuration: {
                $0.isSecureTextEntry = !viewStore.passwordFieldTextVisible
                $0.textContentType = .newPassword
            },
            trailing: {
                PasswordEyeSymbolButton(
                    isPasswordVisible: viewStore.binding(\.$passwordFieldTextVisible)
                )
            },
            onReturnTapped: {
                viewStore.send(.set(\.$selectedInputField, nil))
            }
        )
        .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.passwordGroup)
    }

    private var countryAndStatePickers: some View {
        VStack(alignment: .leading, spacing: Spacing.baseline) {
            let accessory = Icon.chevronDown
                .accentColor(.semantic.muted)
                .frame(width: 12, height: 12)

            Text(LocalizedString.TextFieldTitle.country)
                .typography(.paragraph2)

            VStack(spacing: .zero) {
                let country = viewStore.country.title
                if let state = viewStore.countryState?.title {
                    PrimaryPicker(
                        selection: viewStore.binding(\.$pickerSelection),
                        rows: [
                            .row(
                                title: country,
                                identifier: .country,
                                trailing: { accessory }
                            ),
                            .row(
                                title: state,
                                identifier: .state,
                                trailing: { accessory }
                            )
                        ]
                    )
                } else {
                    PrimaryPicker(
                        selection: viewStore.binding(\.$pickerSelection),
                        rows: [
                            .row(
                                title: country,
                                identifier: .country,
                                trailing: { accessory }
                            )
                        ]
                    )
                }
            }
        }
    }

    private var termsAgreementView: some View {
        HStack(alignment: .top, spacing: Spacing.baseline) {
            let showCheckboxError = viewStore.inputValidationState == .invalid(.termsNotAccepted)
            Checkbox(
                isOn: viewStore.binding(\.$termsAccepted),
                variant: showCheckboxError ? .error : .default
            )
            .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.termsOfServiceButton)

            agreementText
                .typography(.caption1)
                .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.agreementPromptText)
        }
        // fixing the size prevents the view from collapsing when the keyboard is on screen
        .fixedSize(horizontal: false, vertical: true)
    }

    private var agreementText: some View {
        VStack(alignment: .leading, spacing: .zero) {
            let promptTemplate = LocalizedString.agreementPrompt
            let recoveryPhrasePlaceholder = "|RECOVERY_PHRASE|"

            let recoveryPhraseText = Text(LocalizedString.recoveryPhrase)
                .foregroundColor(.semantic.primary)

            let promptComponents = promptTemplate.components(separatedBy: recoveryPhrasePlaceholder)
            let promptText = Text(promptComponents[0]) + recoveryPhraseText + Text(promptComponents[1]) + Text("")

            promptText
                .foregroundColor(.semantic.body)
                .onTapGesture {
                    viewStore.send(.openExternalLink(Constants.SupportURL.ResetAccount.walletBackupURL))
                }
                .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.agreementPromptText)

            HStack(alignment: .firstTextBaseline, spacing: .zero) {
                Text(LocalizedString.termsOfServiceLink)
                    .foregroundColor(.semantic.primary)
                    .onTapGesture {
                        guard let url = URL(string: Constants.HostURL.terms) else { return }
                        viewStore.send(.openExternalLink(url))
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.termsOfServiceButton)

                Text(" " + LocalizedString.and + " ")
                    .foregroundColor(.semantic.body)

                let privacyPolicyComponent = Text(LocalizedString.privacyPolicyLink)
                    .foregroundColor(.semantic.primary)
                let fullStopComponent = Text(".")
                    .foregroundColor(.semantic.body)
                let privacyPolicyText = privacyPolicyComponent + fullStopComponent

                privacyPolicyText
                    .onTapGesture {
                        guard let url = URL(string: Constants.HostURL.privacyPolicy) else { return }
                        viewStore.send(.openExternalLink(url))
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.CreateAccountScreen.privacyPolicyButton)
            }
        }
    }
}

extension PasswordValidationScore {

    fileprivate var displayString: String? {
        switch self {
        case .none:
            return nil
        case .normal:
            return LocalizedString.PasswordStrengthIndicator.regularPassword
        case .strong:
            return LocalizedString.PasswordStrengthIndicator.strongPassword
        case .weak:
            return LocalizedString.PasswordStrengthIndicator.weakPassword
        }
    }

    fileprivate var inputSubTextStyle: InputSubTextStyle {
        switch self {
        case .none, .normal:
            return .primary
        case .strong:
            return .success
        case .weak:
            return .error
        }
    }
}

#if DEBUG
import AnalyticsKit
import ToolKit

struct CreateAccountView_Previews: PreviewProvider {

    static var previews: some View {
        CreateAccountView(
            store: .init(
                initialState: .init(
                    context: .createWallet
                ),
                reducer: createAccountReducer,
                environment: .init(
                    mainQueue: .main,
                    passwordValidator: PasswordValidator(),
                    externalAppOpener: ToLogAppOpener(),
                    analyticsRecorder: NoOpAnalyticsRecorder()
                )
            )
        )
    }
}
#endif
