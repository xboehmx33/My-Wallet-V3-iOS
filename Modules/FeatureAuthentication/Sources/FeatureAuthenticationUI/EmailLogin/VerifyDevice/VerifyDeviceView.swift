// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import ComposableArchitecture
import ComposableNavigation
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

public enum VerifyDeviceRoute: NavigationRoute {
    case credentials
    case upgradeAccount(exchangeOnly: Bool)

    @ViewBuilder
    public func destination(
        in store: Store<VerifyDeviceState, VerifyDeviceAction>
    ) -> some View {
        WithViewStore(store) { viewStore in
            switch self {
            case .credentials:
                IfLetStore(
                    store.scope(
                        state: \.credentialsState,
                        action: VerifyDeviceAction.credentials
                    ),
                    then: { store in
                        CredentialsView(
                            context: viewStore.credentialsContext,
                            store: store
                        )
                    }
                )
            case .upgradeAccount(let exchangeOnly):
                IfLetStore(
                    store.scope(
                        state: \.upgradeAccountState,
                        action: VerifyDeviceAction.upgradeAccount
                    ),
                    then: { store in
                        UpgradeAccountView(
                            store: store,
                            exchangeOnly: exchangeOnly
                        )
                    }
                )
            }
        }
    }
}

struct VerifyDeviceView: View {

    private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.EmailLogin

    private enum Layout {
        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24

        static let imageSideLength: CGFloat = 72
        static let imageBottomPadding: CGFloat = 16
        static let descriptionFontSize: CGFloat = 16
        static let descriptionLineSpacing: CGFloat = 4
        static let buttonSpacing: CGFloat = 10
    }

    private let store: Store<VerifyDeviceState, VerifyDeviceAction>
    private var showOpenMailAppButton: Bool

    init(store: Store<VerifyDeviceState, VerifyDeviceAction>) {
        self.store = store

        if let mailAppURL = URL(string: "message://"),
           UIApplication.shared.canOpenURL(mailAppURL)
        {
            showOpenMailAppButton = true
        } else {
            showOpenMailAppButton = false
        }
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                VStack {
                    Spacer()
                    Image.CircleIcon.verifyDevice
                        .frame(width: Layout.imageSideLength, height: Layout.imageSideLength)
                        .padding(.bottom, Layout.imageBottomPadding)
                        .accessibility(identifier: AccessibilityIdentifiers.VerifyDeviceScreen.verifyDeviceImage)

                    Text(LocalizedString.VerifyDevice.title)
                        .textStyle(.title)
                        .accessibility(identifier: AccessibilityIdentifiers.VerifyDeviceScreen.verifyDeviceTitleText)

                    Text(LocalizedString.VerifyDevice.description)
                        .font(Font(weight: .medium, size: Layout.descriptionFontSize))
                        .foregroundColor(.textSubheading)
                        .lineSpacing(Layout.descriptionLineSpacing)
                        .accessibility(
                            identifier: AccessibilityIdentifiers.VerifyDeviceScreen.verifyDeviceDescriptionText
                        )
                    Spacer()
                }
                .multilineTextAlignment(.center)

                buttonSection
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onWillDisappear {
                viewStore.send(.onWillDisappear)
            }
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: Layout.leadingPadding,
                    bottom: Layout.bottomPadding,
                    trailing: Layout.trailingPadding
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationRoute(in: store)
            .hideBackButtonTitle()
            .alert(self.store.scope(state: \.alert), dismiss: .alert(.dismiss))
        }
    }

    private var buttonSection: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: Layout.buttonSpacing) {
                SecondaryButton(
                    title: LocalizedString.Button.sendAgain,
                    action: {
                        viewStore.send(.sendDeviceVerificationEmail)
                    },
                    loading: viewStore.binding(get: \.sendEmailButtonIsLoading, send: .none)
                )
                .disabled(viewStore.sendEmailButtonIsLoading)
                .accessibility(identifier: AccessibilityIdentifiers.VerifyDeviceScreen.sendAgainButton)
                if showOpenMailAppButton {
                    PrimaryButton(title: LocalizedString.Button.openEmail) {
                        viewStore.send(.openMailApp)
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.VerifyDeviceScreen.openMailAppButton)
                }
            }
        }
    }
}

#if DEBUG
struct VerifyDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        VerifyDeviceView(
            store:
            Store(
                initialState: .init(emailAddress: ""),
                reducer: verifyDeviceReducer,
                environment: .init(
                    mainQueue: .main,
                    deviceVerificationService: NoOpDeviceVerificationService(),
                    featureFlagsService: NoOpFeatureFlagsService(),
                    errorRecorder: NoOpErrorRecorder(),
                    analyticsRecorder: NoOpAnalyticsRecorder()
                )
            )
        )
    }
}
#endif
