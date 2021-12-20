// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import ComposableNavigation
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

public enum WelcomeRoute: NavigationRoute {
    case createWallet
    case emailLogin
    case restoreWallet
    case manualLogin
    case secondPassword

    @ViewBuilder
    public func destination(
        in store: Store<WelcomeState, WelcomeAction>
    ) -> some View {
        let viewStore = ViewStore(store)
        switch self {
        case .createWallet:
            IfLetStore(
                store.scope(
                    state: \.createWalletState,
                    action: WelcomeAction.createWallet
                ),
                then: { store in
                    if viewStore.route?.action == .navigateTo {
                        CreateAccountView(store: store)
                    } else {
                        CreateAccountView(store: store)
                            .trailingNavigationButton(.close) {
                                viewStore.send(.createWallet(.closeButtonTapped))
                            }
                    }
                }
            )
        case .emailLogin:
            IfLetStore(
                store.scope(
                    state: \.emailLoginState,
                    action: WelcomeAction.emailLogin
                ),
                then: EmailLoginView.init(store:)
            )
        case .restoreWallet:
            IfLetStore(
                store.scope(
                    state: \.restoreWalletState,
                    action: WelcomeAction.restoreWallet
                ),
                then: { store in
                    SeedPhraseView(store: store)
                        .trailingNavigationButton(.close) {
                            viewStore.send(.restoreWallet(.closeButtonTapped))
                        }
                        .whiteNavigationBarStyle()
                        .hideBackButtonTitle()
                }
            )
        case .manualLogin:
            IfLetStore(
                store.scope(
                    state: \.manualCredentialsState,
                    action: WelcomeAction.manualPairing
                ),
                then: { store in
                    CredentialsView(
                        context: .manualPairing,
                        store: store
                    )
                    .trailingNavigationButton(.close) {
                        viewStore.send(.manualPairing(.closeButtonTapped))
                    }
                    .whiteNavigationBarStyle()
                    .navigationTitle(
                        LocalizedString.Button.manualPairing
                    )
                }
            )
        case .secondPassword:
            IfLetStore(
                store.scope(
                    state: \.secondPasswordNoticeState,
                    action: WelcomeAction.secondPasswordNotice
                ),
                then: { store in
                    SecondPasswordNoticeView(store: store)
                }
            )
        }
    }
}

private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.Welcome

private enum Layout {
    static let topPadding: CGFloat = 140
    static let bottomPadding: CGFloat = 58
    static let leadingPadding: CGFloat = 24
    static let trailingPadding: CGFloat = 24

    static let imageSideLength: CGFloat = 64
    static let imageBottomPadding: CGFloat = 40
    static let titleFontSize: CGFloat = 24
    static let titleBottomPadding: CGFloat = 16
    static let messageFontSize: CGFloat = 16
    static let messageLineSpacing: CGFloat = 4
    static let buttonSpacing: CGFloat = 10
    static let buttonFontSize: CGFloat = 16
    static let buttonBottomPadding: CGFloat = 20
    static let supplmentaryTextFontSize: CGFloat = 12
}

/// Entry point to Create Wallet/Login/Restore Wallet
public struct WelcomeView: View {

    private let store: Store<WelcomeState, WelcomeAction>
    @ObservedObject private var viewStore: ViewStore<WelcomeState, WelcomeAction>

    public init(store: Store<WelcomeState, WelcomeAction>) {
        self.store = store
        viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            welcomeMessageSection
            Spacer()
            buttonSection
                .padding(.bottom, Layout.buttonBottomPadding)
            supplementarySection
        }
        .padding(
            EdgeInsets(
                top: Layout.topPadding,
                leading: Layout.leadingPadding,
                bottom: Layout.bottomPadding,
                trailing: Layout.trailingPadding
            )
        )
        .navigationRoute(in: store)
    }

    // MARK: - Private

    private var welcomeMessageSection: some View {
        VStack {
            Image.Logo.blockchain
                .frame(width: Layout.imageSideLength, height: Layout.imageSideLength)
                .padding(.bottom, Layout.imageBottomPadding)
                .accessibility(identifier: AccessibilityIdentifiers.WelcomeScreen.blockchainImage)
            Text(LocalizedString.title)
                .font(Font(weight: .semibold, size: Layout.titleFontSize))
                .foregroundColor(.textHeading)
                .padding(.bottom, Layout.titleBottomPadding)
                .accessibility(identifier: AccessibilityIdentifiers.WelcomeScreen.welcomeTitleText)
            welcomeMessageDescription
                .font(Font(weight: .medium, size: Layout.messageFontSize))
                .lineSpacing(Layout.messageLineSpacing)
                .accessibility(identifier: AccessibilityIdentifiers.WelcomeScreen.welcomeMessageText)
        }
        .multilineTextAlignment(.center)
    }

    private var welcomeMessageDescription: some View {
        Text(LocalizedString.Description.prefix)
            .foregroundColor(.textMuted) +
            Text(LocalizedString.Description.send)
            .foregroundColor(.textHeading) +
            Text(LocalizedString.Description.comma)
            .foregroundColor(.textMuted) +
            Text(LocalizedString.Description.receive)
            .foregroundColor(.textHeading) +
            Text(LocalizedString.Description.comma)
            .foregroundColor(.textMuted) +
            Text(LocalizedString.Description.store + "\n")
            .foregroundColor(.textHeading) +
            Text(LocalizedString.Description.and)
            .foregroundColor(.textMuted) +
            Text(LocalizedString.Description.trade)
            .foregroundColor(.textHeading) +
            Text(LocalizedString.Description.suffix)
            .foregroundColor(.textMuted)
    }

    private var buttonSection: some View {
        VStack(spacing: Layout.buttonSpacing) {
            PrimaryButton(title: LocalizedString.Button.buyCryptoNow) {
                viewStore.send(.navigate(to: .createWallet))
            }
            .accessibility(identifier: AccessibilityIdentifiers.WelcomeScreen.createWalletButton)
            SecondaryButton(title: LocalizedString.Button.login) {
                viewStore.send(.enter(into: .emailLogin))
            }
            .accessibility(identifier: AccessibilityIdentifiers.WelcomeScreen.emailLoginButton)
            if viewStore.manualPairingEnabled {
                Divider()
                manualPairingButton()
                    .accessibility(
                        identifier: AccessibilityIdentifiers.WelcomeScreen.manualPairingButton
                    )
            }
        }
        .accessibility(identifier: AccessibilityIdentifiers.WelcomeScreen.emailLoginButton)
    }

    private var supplementarySection: some View {
        HStack {
            Button(LocalizedString.Button.restoreWallet) {
                viewStore.send(.enter(into: .restoreWallet))
            }
            .font(Font(weight: .semibold, size: Layout.supplmentaryTextFontSize))
            .foregroundColor(.buttonLinkText)
            .accessibility(identifier: AccessibilityIdentifiers.WelcomeScreen.restoreWalletButton)
            Spacer()
            Text(viewStore.buildVersion)
                .font(Font(weight: .medium, size: Layout.supplmentaryTextFontSize))
                .foregroundColor(.textMuted)
                .accessibility(identifier: AccessibilityIdentifiers.WelcomeScreen.buildVersionText)
        }
    }

    private func manualPairingButton() -> some View {
        Button(LocalizedString.Button.manualPairing) {
            viewStore.send(.enter(into: .manualLogin))
        }
        .font(Font(weight: .semibold, size: Layout.buttonFontSize))
        .frame(maxWidth: .infinity, minHeight: LayoutConstants.buttonMinHeight)
        .padding(.horizontal)
        .foregroundColor(Color.textSubheading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadious)
                .fill(Color.buttonSecondaryBackground)
        )
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadious)
                .stroke(Color.borderPrimary)
        )
    }
}

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(
            store: Store(
                initialState: .init(),
                reducer: welcomeReducer,
                environment: .init(
                    mainQueue: .main,
                    sessionTokenService: NoOpSessionTokenService(),
                    deviceVerificationService: NoOpDeviceVerificationService(),
                    featureFlagsService: NoOpFeatureFlagsService(),
                    buildVersionProvider: { "Test version" }
                )
            )
        )
    }
}
#endif
