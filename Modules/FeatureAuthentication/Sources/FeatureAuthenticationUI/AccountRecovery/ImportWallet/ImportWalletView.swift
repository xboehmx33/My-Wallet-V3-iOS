// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import Localization
import SwiftUI
import UIComponentsKit

struct ImportWalletView: View {

    private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.ImportWallet

    private enum Layout {
        static let imageSideLength: CGFloat = 72

        static let messageFontSize: CGFloat = 16
        static let messageLineSpacing: CGFloat = 4

        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24
        static let titleTopPadding: CGFloat = 16
        static let buttonBottomPadding: CGFloat = 10
    }

    private let store: Store<ImportWalletState, ImportWalletAction>
    @ObservedObject private var viewStore: ViewStore<ImportWalletState, ImportWalletAction>

    init(store: Store<ImportWalletState, ImportWalletAction>) {
        self.store = store
        viewStore = ViewStore(store)
    }

    var body: some View {
        VStack {
            VStack {
                Spacer()
                Image.CircleIcon.importWallet
                    .frame(width: Layout.imageSideLength, height: Layout.imageSideLength)
                    .accessibility(identifier: AccessibilityIdentifiers.ImportWalletScreen.importWalletImage)

                Text(LocalizedString.importWalletTitle)
                    .textStyle(.title)
                    .padding(.top, Layout.titleTopPadding)
                    .accessibility(identifier: AccessibilityIdentifiers.ImportWalletScreen.importWalletTitleText)

                Text(LocalizedString.importWalletMessage)
                    .font(Font(weight: .medium, size: Layout.messageFontSize))
                    .foregroundColor(.textSubheading)
                    .lineSpacing(Layout.messageLineSpacing)
                    .accessibility(identifier: AccessibilityIdentifiers.ImportWalletScreen.importWalletMessageText)
                Spacer()
            }
            VStack {
                PrimaryButton(title: LocalizedString.Button.importWallet) {
                    viewStore.send(.importWalletButtonTapped)
                }
                .padding(.bottom, Layout.buttonBottomPadding)
                SecondaryButton(title: LocalizedString.Button.goBack) {
                    viewStore.send(.goBackButtonTapped)
                }
            }
            NavigationLink(
                destination: IfLetStore(
                    store.scope(
                        state: \.createAccountState,
                        action: ImportWalletAction.createAccount
                    ),
                    then: CreateAccountView.init(store:)
                ),
                isActive: viewStore.binding(
                    get: \.isCreateAccountScreenVisible,
                    send: ImportWalletAction.setCreateAccountScreenVisible(_:)
                ),
                label: EmptyView.init
            )
        }
        .multilineTextAlignment(.center)
        .navigationBarTitleDisplayMode(.inline)
        .hideBackButtonTitle()
        .padding(
            EdgeInsets(
                top: 0,
                leading: Layout.leadingPadding,
                bottom: Layout.bottomPadding,
                trailing: Layout.trailingPadding
            )
        )
    }
}

#if DEBUG
import AnalyticsKit
import FeatureAuthenticationDomain
import ToolKit

struct ImportWalletView_Previews: PreviewProvider {
    static var previews: some View {
        ImportWalletView(
            store: .init(
                initialState: .init(),
                reducer: importWalletReducer,
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
