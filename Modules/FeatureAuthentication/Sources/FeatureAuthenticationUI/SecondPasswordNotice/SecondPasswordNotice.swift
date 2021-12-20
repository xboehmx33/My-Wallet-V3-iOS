// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

public enum SecondPasswordNotice {
    public enum URLContent: Equatable {
        case loginOnWeb
        case twoFASupport

        var url: URL? {
            switch self {
            case .loginOnWeb:
                return URL(string: Constants.HostURL.loginOnWeb)
            case .twoFASupport:
                return URL(string: Constants.SupportURL.SecondPassword.twoFASupport)
            }
        }
    }

    public struct State: Equatable {}

    public enum Action: Equatable {
        case open(urlContent: URLContent)
        case closeButtonTapped
    }

    struct Environment {
        let externalAppOpener: ExternalAppOpener
    }
}

let secondPasswordNoticeReducer = Reducer<
    SecondPasswordNotice.State,
    SecondPasswordNotice.Action,
    SecondPasswordNotice.Environment
> { _, action, environment in
    switch action {
    case .open(let urlContent):
        guard let url = urlContent.url else {
            return .none
        }
        environment.externalAppOpener.open(url)
        return .none
    case .closeButtonTapped:
        return .none
    }
}

public struct SecondPasswordNoticeView: View {

    private typealias LocalizedConstants = LocalizationConstants.SecondPasswordScreen
    private typealias AccessibilityIdentifier = AccessibilityIdentifiers.SecondPasswordScreen

    private enum Layout {
        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24

        static let imageBottomPadding: CGFloat = 16
        static let descriptionFontSize: CGFloat = 16
        static let descriptionLineSpacing: CGFloat = 4
        static let buttonSpacing: CGFloat = 10
        /// magic numbers from Figma file
        static let learnMoreMinWidth: CGFloat = 100
        static let learnMoreMaxWidth: CGFloat = 120
        static let learnMoreIdealHeight: CGFloat = 32
    }

    private let store: Store<SecondPasswordNotice.State, SecondPasswordNotice.Action>

    public init(store: Store<SecondPasswordNotice.State, SecondPasswordNotice.Action>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                VStack {
                    Spacer()
                    Image.CircleIcon.lockedIcon
                        .padding(.bottom, Layout.imageBottomPadding)
                        .accessibility(identifier: AccessibilityIdentifier.lockedIconImage)

                    Text(LocalizedConstants.title)
                        .textStyle(.title)
                        .accessibility(identifier: AccessibilityIdentifier.titleText)

                    Text(LocalizedConstants.description)
                        .font(Font(weight: .medium, size: Layout.descriptionFontSize))
                        .foregroundColor(.textSubheading)
                        .lineSpacing(Layout.descriptionLineSpacing)
                        .accessibility(
                            identifier: AccessibilityIdentifier.descriptionText
                        )
                    SecondaryButton(title: LocalizedConstants.learnMore) {
                        viewStore.send(.open(urlContent: .twoFASupport))
                    }
                    .frame(
                        minWidth: Layout.learnMoreMinWidth,
                        maxWidth: Layout.learnMoreMaxWidth,
                        idealHeight: Layout.learnMoreIdealHeight,
                        alignment: .center
                    )
                    .accessibility(identifier: AccessibilityIdentifier.learnMoreText)
                    Spacer()
                }
                .multilineTextAlignment(.center)

                VStack(spacing: Layout.buttonSpacing) {
                    PrimaryButton(
                        title: LocalizedConstants.loginOnWebButtonTitle,
                        action: { viewStore.send(.open(urlContent: .loginOnWeb)) }
                    )
                    .accessibility(identifier: AccessibilityIdentifier.loginOnWebButton)
                }
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
            .whiteNavigationBarStyle()
            .trailingNavigationButton(.close) {
                viewStore.send(.closeButtonTapped)
            }
        }
    }
}

#if DEBUG
struct SecondPasswordNoticeView_Previews: PreviewProvider {
    static var previews: some View {
        SecondPasswordNoticeView(
            store: Store(
                initialState: .init(),
                reducer: secondPasswordNoticeReducer,
                environment: SecondPasswordNotice.Environment(
                    externalAppOpener: ToLogAppOpener()
                )
            )
        )
    }
}
#endif
