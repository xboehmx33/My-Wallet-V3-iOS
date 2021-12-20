// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import RxSwift

/// An `AccountGroup` containing only Non Custodial accounts.
public class CryptoAccountNonCustodialGroup: AccountGroup {
    private typealias LocalizedString = LocalizationConstants.AccountGroup

    private let asset: CryptoCurrency

    public private(set) lazy var identifier: AnyHashable = "CryptoAccountNonCustodialGroup." + asset.code

    public let label: String

    public let accounts: [SingleAccount]

    public var requireSecondPassword: Single<Bool> {
        if accounts.isEmpty {
            return .just(false)
        }
        return Single
            .zip(accounts.map(\.requireSecondPassword))
            .map { values -> Bool in
                values.contains(true)
            }
    }

    public var actionableBalance: Single<MoneyValue> {
        if accounts.isEmpty {
            return .just(.zero(currency: asset))
        }
        return Single
            .zip(accounts.map(\.actionableBalance))
            .map { [asset] values -> MoneyValue in
                try values.reduce(.zero(currency: asset), +)
            }
    }

    public var receiveAddress: Single<ReceiveAddress> {
        .error(AccountGroupError.noReceiveAddress)
    }

    public var isFunded: Single<Bool> {
        if accounts.isEmpty {
            return .just(false)
        }
        return Single
            .zip(accounts.map(\.isFunded))
            .map { values -> Bool in
                values.contains(true)
            }
    }

    public var pendingBalance: Single<MoneyValue> {
        if accounts.isEmpty {
            return .just(.zero(currency: asset))
        }
        return Single
            .zip(accounts.map(\.pendingBalance))
            .map { [asset] values -> MoneyValue in
                try values.reduce(.zero(currency: asset), +)
            }
    }

    public var balance: Single<MoneyValue> {
        if accounts.isEmpty {
            return .just(.zero(currency: asset))
        }
        return Single
            .zip(accounts.map(\.balance))
            .map { [asset] values -> MoneyValue in
                try values.reduce(.zero(currency: asset), +)
            }
    }

    public init(asset: CryptoCurrency, accounts: [SingleAccount]) {
        self.asset = asset
        label = String(format: LocalizedString.myWallets, asset.name)
        self.accounts = accounts
    }
}
