// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import ComposableArchitecture
import FeatureAccountPickerDomain
import Localization
import SwiftUI
import UIComponentsKit

struct AccountPickerRowView<
    BadgeView: View,
    IconView: View,
    MultiBadgeView: View,
    WithdrawalLocksView: View
>: View {

    // MARK: - Internal properties

    let model: AccountPickerRow
    let send: (SuccessRowsAction) -> Void
    let badgeView: (AnyHashable) -> BadgeView
    let iconView: (AnyHashable) -> IconView
    let multiBadgeView: (AnyHashable) -> MultiBadgeView
    let withdrawalLocksView: () -> WithdrawalLocksView
    let fiatBalance: String?
    let cryptoBalance: String?
    let currencyCode: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            switch model {
            case .label(let model):
                Text(model.text)
            case .accountGroup(let model):
                AccountGroupRow(
                    model: model,
                    badgeView: badgeView(model.id),
                    fiatBalance: fiatBalance,
                    currencyCode: currencyCode
                )
                PrimaryDivider()
            case .button(let model):
                ButtonRow(model: model) {
                    send(.accountPickerRowDidTap(model.id))
                }
                PrimaryDivider()
            case .linkedBankAccount(let model):
                LinkedBankAccountRow(
                    model: model,
                    badgeView: badgeView(model.id),
                    multiBadgeView: multiBadgeView(model.id)
                )
                PrimaryDivider()
            case .paymentMethodAccount(let model):
                PaymentMethodRow(
                    model: model
                )
                PrimaryDivider()
            case .singleAccount(let model):
                SingleAccountRow(
                    model: model,
                    badgeView: badgeView(model.id),
                    iconView: iconView(model.id),
                    multiBadgeView: multiBadgeView(model.id),
                    fiatBalance: fiatBalance,
                    cryptoBalance: cryptoBalance
                )
                PrimaryDivider()
            case .withdrawalLocks:
                withdrawalLocksView()
            }
        }
        .onTapGesture {
            send(.accountPickerRowDidTap(model.id))
        }
    }
}

// MARK: - Specific Rows

private struct AccountGroupRow<BadgeView: View>: View {

    let model: AccountPickerRow.AccountGroup
    let badgeView: BadgeView
    let fiatBalance: String?
    let currencyCode: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 16) {
                badgeView
                    .frame(width: 32, height: 32)
                    .padding(6)
                VStack {
                    HStack {
                        Text(model.title)
                            .textStyle(.heading)
                        Spacer()
                        Text(fiatBalance ?? " ")
                            .textStyle(.heading)
                            .shimmer(
                                enabled: fiatBalance == nil,
                                width: 90
                            )
                    }
                    HStack {
                        Text(model.description)
                            .textStyle(.subheading)
                        Spacer()
                        Text(currencyCode ?? " ")
                            .textStyle(.subheading)
                            .shimmer(
                                enabled: currencyCode == nil,
                                width: 100
                            )
                    }
                }
            }
            .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 24))
        }
    }
}

private struct ButtonRow: View {

    let model: AccountPickerRow.Button
    let action: () -> Void

    var body: some View {
        VStack {
            UIComponentsKit.SecondaryButton(title: model.text) {
                action()
            }
            .frame(height: 48)
        }
        .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
    }
}

private struct LinkedBankAccountRow<BadgeView: View, MultiBadgeView: View>: View {

    let model: AccountPickerRow.LinkedBankAccount
    let badgeView: BadgeView
    let multiBadgeView: MultiBadgeView

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    badgeView
                        .frame(width: 32, height: 32)
                        .padding(6)
                    Spacer()
                        .frame(width: 16)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.title)
                                .textStyle(.heading)
                            Text(model.description)
                                .textStyle(.subheading)
                        }
                    }
                }

                multiBadgeView
                    .padding(.top, 8)
            }
            .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 24))
        }
    }
}

private struct PaymentMethodRow: View {

    let model: AccountPickerRow.PaymentMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                ZStack {
                    model.badgeView
                        .frame(width: 32, height: 32)
                        .scaledToFit()
                }
                .frame(width: 32, height: 32)
                .padding(6)
                .background(model.badgeBackground)
                .clipShape(Circle())

                Spacer()
                    .frame(width: 16)

                VStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.title)
                            .textStyle(.heading)
                        Text(model.description)
                            .textStyle(.subheading)
                    }
                }
                .offset(x: 0, y: -2) // visually align due to font padding
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 24))
    }
}

private struct SingleAccountRow<
    BadgeView: View,
    IconView: View,
    MultiBadgeView: View
>: View {

    let model: AccountPickerRow.SingleAccount
    let badgeView: BadgeView
    let iconView: IconView
    let multiBadgeView: MultiBadgeView
    let fiatBalance: String?
    let cryptoBalance: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            badgeView
                                .frame(width: 32, height: 32)
                        }
                        .padding(6)

                        iconView
                            .frame(width: 16, height: 16)
                    }
                    Spacer()
                        .frame(width: 16)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.title)
                                .textStyle(.heading)
                                .scaledToFill()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Text(model.description)
                                .textStyle(.subheading)
                                .scaledToFill()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(fiatBalance ?? " ")
                                .textStyle(.heading)
                                .scaledToFill()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .shimmer(
                                    enabled: fiatBalance == nil,
                                    width: 90
                                )
                            Text(cryptoBalance ?? " ")
                                .textStyle(.subheading)
                                .scaledToFill()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .shimmer(
                                    enabled: cryptoBalance == nil,
                                    width: 100
                                )
                        }
                    }
                }
                multiBadgeView
            }
            .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 24))
        }
    }
}

struct AccountPickerRowView_Previews: PreviewProvider {

    static let accountGroupIdentifier = UUID()
    static let singleAccountIdentifier = UUID()

    static let accountGroupRow = AccountPickerRow.accountGroup(
        AccountPickerRow.AccountGroup(
            id: UUID(),
            title: "All Wallets",
            description: "Total Balance"
        )
    )

    static let buttonRow = AccountPickerRow.button(
        AccountPickerRow.Button(
            id: UUID(),
            text: "See Balance"
        )
    )

    static let linkedBankAccountRow = AccountPickerRow.linkedBankAccount(
        AccountPickerRow.LinkedBankAccount(
            id: UUID(),
            title: "BTC",
            description: "5243424"
        )
    )

    static let paymentMethodAccountRow = AccountPickerRow.paymentMethodAccount(
        AccountPickerRow.PaymentMethod(
            id: UUID(),
            title: "Visa •••• 0000",
            description: "$1,200",
            badgeView: Image(systemName: "creditcard"),
            badgeBackground: .badgeBackgroundInfo
        )
    )

    static let singleAccountRow = AccountPickerRow.singleAccount(
        AccountPickerRow.SingleAccount(
            id: UUID(),
            title: "BTC Trading Wallet",
            description: "Bitcoin"
        )
    )

    static var previews: some View {
        Group {
            AccountPickerRowView(
                model: accountGroupRow,
                send: { _ in },
                badgeView: { _ in EmptyView() },
                iconView: { _ in EmptyView() },
                multiBadgeView: { _ in EmptyView() },
                withdrawalLocksView: { EmptyView() },
                fiatBalance: "$2,302.39",
                cryptoBalance: "0.21204887 BTC",
                currencyCode: "USD"
            )
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .previewDisplayName("AccountGroupRow")

            AccountPickerRowView(
                model: buttonRow,
                send: { _ in },
                badgeView: { _ in EmptyView() },
                iconView: { _ in EmptyView() },
                multiBadgeView: { _ in EmptyView() },
                withdrawalLocksView: { EmptyView() },
                fiatBalance: nil,
                cryptoBalance: nil,
                currencyCode: nil
            )
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .previewDisplayName("ButtonRow")

            AccountPickerRowView(
                model: linkedBankAccountRow,
                send: { _ in },
                badgeView: { _ in EmptyView() },
                iconView: { _ in EmptyView() },
                multiBadgeView: { _ in EmptyView() },
                withdrawalLocksView: { EmptyView() },
                fiatBalance: nil,
                cryptoBalance: nil,
                currencyCode: nil
            )
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .previewDisplayName("LinkedBankAccountRow")

            AccountPickerRowView(
                model: paymentMethodAccountRow,
                send: { _ in },
                badgeView: { _ in EmptyView() },
                iconView: { _ in EmptyView() },
                multiBadgeView: { _ in EmptyView() },
                withdrawalLocksView: { EmptyView() },
                fiatBalance: nil,
                cryptoBalance: nil,
                currencyCode: nil
            )
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .previewDisplayName("PaymentMethodAccountRow")

            AccountPickerRowView(
                model: singleAccountRow,
                send: { _ in },
                badgeView: { _ in EmptyView() },
                iconView: { _ in EmptyView() },
                multiBadgeView: { _ in EmptyView() },
                withdrawalLocksView: { EmptyView() },
                fiatBalance: "$2,302.39",
                cryptoBalance: "0.21204887 BTC",
                currencyCode: nil
            )
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .previewDisplayName("SingleAccountRow")
        }
        EmptyView()
    }
}
