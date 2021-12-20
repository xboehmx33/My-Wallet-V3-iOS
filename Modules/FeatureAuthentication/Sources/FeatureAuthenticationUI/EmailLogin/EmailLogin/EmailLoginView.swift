// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import ComposableArchitecture
import ComposableNavigation
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

public enum EmailLoginRoute: NavigationRoute {
    case verifyDevice

    @ViewBuilder
    public func destination(
        in store: Store<EmailLoginState, EmailLoginAction>
    ) -> some View {
        switch self {
        case .verifyDevice:
            IfLetStore(
                store.scope(
                    state: \.verifyDeviceState,
                    action: EmailLoginAction.verifyDevice
                ),
                then: VerifyDeviceView.init(store:)
            )
        }
    }
}

public struct EmailLoginView: View {

    private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.EmailLogin

    private enum Layout {
        static let topPadding: CGFloat = 34
        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24

        static let navigationTitleFontSize: CGFloat = 20
        static let navigationTitleTopPadding: CGFloat = 15
    }

    private let store: Store<EmailLoginState, EmailLoginAction>

    @State private var isEmailFieldFirstResponder: Bool = true

    public init(store: Store<EmailLoginState, EmailLoginAction>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                emailField
                    .accessibility(identifier: AccessibilityIdentifiers.EmailLoginScreen.emailGroup)

                Spacer()

                PrimaryButton(
                    title: LocalizedString.Button._continue,
                    action: {
                        viewStore.send(.sendDeviceVerificationEmail)
                    },
                    loading: .constant(viewStore.isLoading)
                )
                .disabled(!viewStore.isEmailValid)
                .accessibility(identifier: AccessibilityIdentifiers.EmailLoginScreen.continueButton)
            }
            .padding(
                EdgeInsets(
                    top: Layout.topPadding,
                    leading: Layout.leadingPadding,
                    bottom: Layout.bottomPadding,
                    trailing: Layout.trailingPadding
                )
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(LocalizedString.navigationTitle)
                        .font(Font(weight: .semibold, size: Layout.navigationTitleFontSize))
                        .padding(.top, Layout.navigationTitleTopPadding)
                        .accessibility(identifier: AccessibilityIdentifiers.EmailLoginScreen.loginTitleText)
                }
            }
            .navigationRoute(in: store)
            .trailingNavigationButton(.close) {
                viewStore.send(.closeButtonTapped)
            }
            .whiteNavigationBarStyle()
            .hideBackButtonTitle()
            .alert(self.store.scope(state: \.alert), dismiss: .alert(.dismiss))
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }

    private var emailField: some View {
        WithViewStore(store) { viewStore in
            FormTextFieldGroup(
                text: viewStore.binding(
                    get: { $0.emailAddress },
                    send: { .didChangeEmailAddress($0) }
                ),
                isFirstResponder: $isEmailFieldFirstResponder,
                isError: .constant(!viewStore.isEmailValid && !viewStore.emailAddress.isEmpty),
                title: LocalizedString.TextFieldTitle.email,
                configuration: {
                    $0.autocorrectionType = .no
                    $0.autocapitalizationType = .none
                    $0.textContentType = .emailAddress
                    $0.keyboardType = .emailAddress
                    $0.placeholder = LocalizedString.TextFieldPlaceholder.email
                    $0.returnKeyType = .done
                    $0.enablesReturnKeyAutomatically = true
                },
                errorMessage: LocalizedString.TextFieldError.invalidEmail,
                onPaddingTapped: {
                    self.isEmailFieldFirstResponder = true
                },
                onReturnTapped: {
                    self.isEmailFieldFirstResponder = false
                    if viewStore.isEmailValid {
                        viewStore.send(.sendDeviceVerificationEmail)
                    }
                }
            )
            .disabled(viewStore.isLoading)
        }
    }
}

#if DEBUG
struct EmailLoginView_Previews: PreviewProvider {
    static var previews: some View {
        EmailLoginView(
            store:
            Store(
                initialState: .init(),
                reducer: emailLoginReducer,
                environment: .init(
                    mainQueue: .main,
                    sessionTokenService: NoOpSessionTokenService(),
                    deviceVerificationService: NoOpDeviceVerificationService(),
                    featureFlagsService: NoOpFeatureFlagsService(),
                    errorRecorder: NoOpErrorRecoder(),
                    analyticsRecorder: NoOpAnalyticsRecorder()
                )
            )
        )
    }
}
#endif
