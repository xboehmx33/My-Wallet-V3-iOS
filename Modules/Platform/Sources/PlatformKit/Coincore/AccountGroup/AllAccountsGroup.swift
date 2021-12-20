// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import RxSwift
import ToolKit

/// An `AccountGroup` containing all accounts.
public final class AllAccountsGroup: AccountGroup {
    private typealias LocalizedString = LocalizationConstants.AccountGroup

    public let accounts: [SingleAccount]
    public let identifier: AnyHashable = "AllAccountsGroup"
    public let label: String = LocalizedString.allWallets
    let actions: AvailableActions = [.viewActivity]

    public var isFunded: Single<Bool> {
        guard !accounts.isEmpty else {
            return .just(false)
        }
        return Single
            .zip(accounts.map(\.isFunded))
            .map { values -> Bool in
                !values.contains(false)
            }
    }

    public var requireSecondPassword: Single<Bool> {
        guard !accounts.isEmpty else {
            return .just(false)
        }

        return Single
            .zip(accounts.map(\.requireSecondPassword))
            .map { values -> Bool in
                !values.contains(false)
            }
    }

    public var pendingBalance: Single<MoneyValue> {
        guard !accounts.isEmpty else {
            return .error(AccountGroupError.noAccounts)
        }
        return Single
            .zip(accounts.map(\.pendingBalance))
            .map { [currencyType] values -> MoneyValue in
                try values.reduce(.zero(currency: currencyType), +)
            }
    }

    public var balance: Single<MoneyValue> {
        guard !accounts.isEmpty else {
            return .error(AccountGroupError.noAccounts)
        }
        return Single
            .zip(accounts.map(\.balance))
            .map { [currencyType] values -> MoneyValue in
                try values.reduce(.zero(currency: currencyType), +)
            }
    }

    public var actionableBalance: Single<MoneyValue> {
        guard !accounts.isEmpty else {
            return .error(AccountGroupError.noAccounts)
        }
        return Single
            .zip(accounts.map(\.actionableBalance))
            .map { [currencyType] values -> MoneyValue in
                try values.reduce(.zero(currency: currencyType), +)
            }
    }

    public var receiveAddress: Single<ReceiveAddress> {
        .error(ReceiveAddressError.notSupported)
    }

    public init(accounts: [SingleAccount]) {
        self.accounts = accounts
    }
}
