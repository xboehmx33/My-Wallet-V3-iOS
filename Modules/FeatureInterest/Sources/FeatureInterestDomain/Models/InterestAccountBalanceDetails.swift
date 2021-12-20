// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public struct InterestAccountBalanceDetails: Equatable {
    public let balance: String?
    public let pendingInterest: String?
    public let totalInterest: String?
    public let pendingWithdrawal: String?
    public let pendingDeposit: String?

    private let currencyCode: String?

    public init(
        balance: String? = nil,
        pendingInterest: String? = nil,
        totalInterest: String? = nil,
        pendingWithdrawal: String? = nil,
        pendingDeposit: String? = nil,
        code: String? = nil
    ) {
        self.balance = balance
        self.pendingDeposit = pendingDeposit
        self.pendingInterest = pendingInterest
        self.totalInterest = totalInterest
        self.pendingWithdrawal = pendingWithdrawal
        currencyCode = code
    }
}

extension InterestAccountBalanceDetails {
    public var currencyType: CurrencyType? {
        guard let code = currencyCode else {
            return nil
        }
        guard let currencyType = try? CurrencyType(code: code) else {
            return nil
        }
        return currencyType
    }

    public var moneyBalance: MoneyValue? {
        guard let currency = currencyType else { return nil }
        return MoneyValue.create(minor: balance ?? "0", currency: currency)
    }

    public var moneyPendingInterest: MoneyValue? {
        guard let currency = currencyType else { return nil }
        return MoneyValue.create(minor: pendingInterest ?? "0", currency: currency)
    }

    public var moneyTotalInterest: MoneyValue? {
        guard let currency = currencyType else { return nil }
        return MoneyValue.create(minor: totalInterest ?? "0", currency: currency)
    }

    public var moneyPendingWithdrawal: MoneyValue? {
        guard let currency = currencyType else { return nil }
        return MoneyValue.create(minor: pendingWithdrawal ?? "0", currency: currency)
    }

    public var moneyPendingDeposit: MoneyValue? {
        guard let currency = currencyType else { return nil }
        return MoneyValue.create(minor: pendingDeposit ?? "0", currency: currency)
    }
}
