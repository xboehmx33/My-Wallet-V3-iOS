// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import Localization
import PlatformUIKit
import SwiftUI
import UIComponentsKit

struct InterestIdentityVerificationView: View {

    private typealias LocalizationId = LocalizationConstants.Interest.Screen.IdentityVerification
    private typealias LocalizationList = LocalizationId.List

    private let buttonTapped: () -> Void

    init(action: @escaping () -> Void) {
        buttonTapped = action
    }

    var body: some View {
        ActionableView(
            content: {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        badgeImageViewWithViewModel(
                            .init(theme:
                                .init(
                                    backgroundColor: .defaultBadge,
                                    cornerRadius: .round,
                                    imageViewContent: .init(
                                        imageResource: .local(
                                            name: "icon_interest",
                                            bundle: .platformUIKit
                                        ),
                                        accessibility: .none,
                                        renderingMode: .template(.white)
                                    ),
                                    marginOffset: 0,
                                    sizingType: .configuredByOwner
                                )
                            )
                        )
                        .frame(width: 32.0, height: 32.0)
                        Text(LocalizationId.title)
                            .textStyle(.title)
                        Text(LocalizationId.description)
                            .textStyle(.subheading)
                    }
                    Divider()
                    Spacer(minLength: Spacing.padding2)
                    VStack(alignment: .leading, spacing: Spacing.padding2) {
                        NumberedBadgeView(
                            badgeText: "1",
                            title: LocalizationList.First.title,
                            description: LocalizationList.First.description
                        )
                        NumberedBadgeView(
                            badgeText: "2",
                            title: LocalizationList.Second.title,
                            description: LocalizationList.Second.description
                        )
                        NumberedBadgeView(
                            badgeText: "3",
                            title: LocalizationList.Third.title,
                            description: LocalizationList.Third.description
                        )
                    }
                    Spacer(minLength: Spacing.padding2)
                }
            },
            buttons: [.init(title: LocalizationId.action, action: buttonTapped)]
        )
    }

    private func badgeImageViewWithViewModel(_ viewModel: BadgeImageViewModel) -> AnyView {
        AnyView(
            BadgeImageViewRepresentable(
                viewModel: viewModel,
                size: 32
            )
        )
    }
}

struct NumberedBadgeView: View {

    private let badgeText: String
    private let title: String
    private let description: String

    init(
        badgeText: String,
        title: String,
        description: String
    ) {
        self.badgeText = badgeText
        self.title = title
        self.description = description
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16.0) {
            Text(badgeText)
                .textStyle(.heading)
                .foregroundColor(Color.buttonSecondaryText)
                .padding()
                .background(Color.badgeBackgroundInfo)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4.0) {
                Text(title)
                    .textStyle(.title)
                    .fixedSize(horizontal: false, vertical: true)
                Text(description)
                    .textStyle(.subheading)
            }
        }
    }

    private func badgeViewWithViewModel(_ viewModel: BadgeViewModel) -> AnyView {
        AnyView(
            BadgeViewRepresentable(
                viewModel: viewModel,
                size: 32
            )
        )
    }
}

struct InterestIdentityVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        InterestIdentityVerificationView(action: {})
    }
}