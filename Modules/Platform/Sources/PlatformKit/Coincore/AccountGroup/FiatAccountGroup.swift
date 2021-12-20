// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import RxSwift

/// An `AccountGroup` containing only fiat accounts.
public class FiatAccountGroup: AccountGroup {

    private typealias LocalizedString = LocalizationConstants.AccountGroup

    public private(set) lazy var identifier: AnyHashable = "FiatAccountGroup"

    public let label: String

    public let accounts: [SingleAccount]

    public var requireSecondPassword: Single<Bool> {
        .just(false)
    }

    public var isFunded: Single<Bool> {
        .error(AccountGroupError.noBalance)
    }

    public var receiveAddress: Single<ReceiveAddress> {
        .error(AccountGroupError.noReceiveAddress)
    }

    public var actionableBalance: Single<MoneyValue> {
        .error(AccountGroupError.noBalance)
    }

    public var pendingBalance: Single<MoneyValue> {
        .error(AccountGroupError.noBalance)
    }

    public var balance: Single<MoneyValue> {
        .error(AccountGroupError.noBalance)
    }

    public func invalidateAccountBalance() {
        accounts.forEach { $0.invalidateAccountBalance() }
    }

    public init(accounts: [SingleAccount]) {
        label = "Fiat Accounts"
        self.accounts = accounts
    }
}
