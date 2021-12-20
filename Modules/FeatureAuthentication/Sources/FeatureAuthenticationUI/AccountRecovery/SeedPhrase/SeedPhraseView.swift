// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import ComposableArchitecture
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

public struct SeedPhraseView: View {

    // MARK: - Type

    private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.SeedPhrase

    private enum Layout {
        static let topPadding: CGFloat = 20
        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24
        static let instructionBottomPadding: CGFloat = 8
        static let resetAccountCallOutTopPadding: CGFloat = 10

        static let cornerRadius: CGFloat = 8
        static let fontSize: CGFloat = 12

        static let textEditorBorderWidth: CGFloat = 1
        static let textEditorHeight: CGFloat = 96
        static let resetAccountTextSpacing: CGFloat = 2

        static let textEditorInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        static let textEditorPlaceholderInsets = EdgeInsets(top: 20, leading: 16, bottom: 14, trailing: 14)
        static let callOutInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        static let largeNavigationTitleFontSize: CGFloat = 20
        static let largeNavigationTitleTopPadding: CGFloat = 15
    }

    // MARK: - Properties

    private let store: Store<SeedPhraseState, SeedPhraseAction>
    @ObservedObject private var viewStore: ViewStore<SeedPhraseState, SeedPhraseAction>

    private var textEditorBorderColor: Color {
        switch viewStore.seedPhraseScore {
        case .valid, .incomplete, .none:
            return .borderPrimary
        case .invalid, .excess:
            return .borderError
        }
    }

    // MARK: - Setup

    public init(store: Store<SeedPhraseState, SeedPhraseAction>) {
        self.store = store
        viewStore = ViewStore(store)
    }

    // MARK: - SwiftUI

    public var body: some View {
        VStack(alignment: .leading) {
            instructionText
                .padding(.bottom, Layout.instructionBottomPadding)
                .accessibility(identifier: AccessibilityIdentifiers.SeedPhraseScreen.instructionText)

            seedPhraseTextEditor
                .accessibility(identifier: AccessibilityIdentifiers.SeedPhraseScreen.seedPhraseTextEditor)

            if viewStore.seedPhraseScore.isInvalid {
                invalidSeedPhraseErrorText
                    .accessibility(identifier: AccessibilityIdentifiers.SeedPhraseScreen.invalidPhraseErrorText)
            }

            if viewStore.context == .troubleLoggingIn {
                resetAccountCallOut
                    .padding(.top, Layout.resetAccountCallOutTopPadding)
            }

            Spacer()

            PrimaryButton(
                title: viewStore.context == .troubleLoggingIn ?
                    LocalizedString.loginInButton :
                    LocalizedString.NavigationTitle.restoreWallet
            ) {
                viewStore.send(
                    .restoreWallet(.metadataRecovery(seedPhrase: viewStore.seedPhrase))
                )
            }
            .disabled(!viewStore.seedPhraseScore.isValid)
            .accessibility(identifier: AccessibilityIdentifiers.SeedPhraseScreen.continueButton)

            NavigationLink(
                destination: IfLetStore(
                    store.scope(
                        state: \.resetPasswordState,
                        action: SeedPhraseAction.resetPassword
                    ),
                    then: { store in
                        ResetPasswordView(store: store)
                    }
                ),
                isActive: viewStore.binding(
                    get: \.isResetPasswordScreenVisible,
                    send: SeedPhraseAction.setResetPasswordScreenVisible(_:)
                ),
                label: EmptyView.init
            )

            NavigationLink(
                destination: IfLetStore(
                    store.scope(
                        state: \.lostFundsWarningState,
                        action: SeedPhraseAction.lostFundsWarning
                    ),
                    then: { store in
                        LostFundsWarningView(store: store)
                    }
                ),
                isActive: viewStore.binding(
                    get: \.isLostFundsWarningScreenVisible,
                    send: SeedPhraseAction.setLostFundsWarningScreenVisible(_:)
                ),
                label: EmptyView.init
            )

            NavigationLink(
                destination: IfLetStore(
                    store.scope(
                        state: \.importWalletState,
                        action: SeedPhraseAction.importWallet
                    ),
                    then: { store in
                        ImportWalletView(store: store)
                    }
                ),
                isActive: viewStore.binding(
                    get: \.isImportWalletScreenVisible,
                    send: SeedPhraseAction.setImportWalletScreenVisible(_:)
                ),
                label: EmptyView.init
            )
        }
        .sheet(
            isPresented: viewStore.binding(
                get: \.isResetAccountBottomSheetVisible,
                send: .none
            )
        ) {
            IfLetStore(
                store.scope(
                    state: \.resetAccountWarningState,
                    action: SeedPhraseAction.resetAccountWarning
                ),
                then: ResetAccountWarningView.init(store:)
            )
        }
        .modifier(CustomNavigationTitle(viewStore: viewStore))
        .hideBackButtonTitle()
        .padding(
            EdgeInsets(
                top: Layout.topPadding,
                leading: Layout.leadingPadding,
                bottom: Layout.bottomPadding,
                trailing: Layout.trailingPadding
            )
        )
    }

    private struct CustomNavigationTitle: ViewModifier {
        let viewStore: ViewStore<SeedPhraseState, SeedPhraseAction>

        @ViewBuilder
        func body(content: Content) -> some View {
            if viewStore.context == .restoreWallet {
                content.whiteNavigationBarStyle().toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text(LocalizedString.NavigationTitle.restoreWallet)
                            .font(Font(weight: .semibold, size: Layout.largeNavigationTitleFontSize))
                            .padding(.top, Layout.largeNavigationTitleTopPadding)
                    }
                }
            } else {
                content.whiteNavigationBarStyle().navigationBarTitle(
                    LocalizedString.NavigationTitle.troubleLoggingIn,
                    displayMode: .inline
                )
            }
        }
    }

    private var instructionText: some View {
        Text(viewStore.context == .troubleLoggingIn ?
            LocalizedString.instruction :
            LocalizedString.restoreWalletInstruction
        )
        .textStyle(.body)
        .multilineTextAlignment(.leading)
    }

    private var seedPhraseTextEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(
                text: viewStore.binding(
                    get: { $0.seedPhrase.lowercased() },
                    send: { .didChangeSeedPhrase($0.lowercased()) }
                )
            )
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .padding(Layout.textEditorInsets)
            .textStyle(.formField)
            .frame(maxHeight: Layout.textEditorHeight)
            .background(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(textEditorBorderColor, lineWidth: Layout.textEditorBorderWidth)
            )
            if viewStore.seedPhrase.isEmpty {
                Text(LocalizedString.placeholder)
                    .padding(Layout.textEditorPlaceholderInsets)
                    .textStyle(.formFieldPlaceholder)
            }
        }
    }

    private var invalidSeedPhraseErrorText: some View {
        Text(LocalizedString.invalidPhrase)
            .font(Font(weight: .medium, size: Layout.fontSize))
            .foregroundColor(.textError)
    }

    private var resetAccountCallOut: some View {
        HStack(spacing: Layout.resetAccountTextSpacing) {
            Text(LocalizedString.resetAccountPrompt)
                .font(Font(weight: .medium, size: Layout.fontSize))
                .foregroundColor(.textSubheading)
                .accessibility(identifier: AccessibilityIdentifiers.SeedPhraseScreen.resetAccountPromptText)

            if viewStore.accountResettable {
                Button(LocalizedString.resetAccountLink) {
                    viewStore.send(.setResetAccountBottomSheetVisible(true))
                }
                .font(Font(weight: .medium, size: Layout.fontSize))
                .foregroundColor(Color.buttonPrimaryBackground)
                .accessibility(identifier: AccessibilityIdentifiers.SeedPhraseScreen.resetAccountButton)
            } else {
                Button(LocalizedString.contactSupportLink) {
                    viewStore.send(.open(urlContent: .contactSupport))
                }
                .font(Font(weight: .medium, size: Layout.fontSize))
                .foregroundColor(Color.buttonPrimaryBackground)
                .accessibility(identifier: AccessibilityIdentifiers.SeedPhraseScreen.contactSupportButton)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color.textCallOutBackground)
        )
    }
}

#if DEBUG
struct SeedPhraseView_Previews: PreviewProvider {
    static var previews: some View {
        SeedPhraseView(
            store: .init(
                initialState: .init(context: .restoreWallet, emailAddress: ""),
                reducer: seedPhraseReducer,
                environment: .init(
                    mainQueue: .main,
                    externalAppOpener: ToLogAppOpener(),
                    analyticsRecorder: NoOpAnalyticsRecorder()
                )
            )
        )
    }
}
#endif
