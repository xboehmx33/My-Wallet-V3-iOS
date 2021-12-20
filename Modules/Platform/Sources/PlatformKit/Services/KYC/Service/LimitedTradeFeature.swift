// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public struct LimitedTradeFeature: Identifiable, Equatable {

    public enum Identifier: String, Hashable {
        case send = "SEND_CRYPTO"
        case receive = "RECEIVE_CRYPTO"
        case swap = "SWAP_CRYPTO"
        case sell = "BUY_AND_SELL"
        case buyWithCard = "BUY_WITH_CARD"
        case buyWithBankAccount = "BUY_AND_DEPOSIT_WITH_BANK"
        case withdraw = "WITHDRAW_WITH_BANK"
        case rewards = "SAVINGS_INTEREST"
    }

    public enum TimePeriod: Equatable {
        case day, month, year
    }

    public struct PeriodicLimit: Equatable {

        public let value: MoneyValue?
        public let period: TimePeriod

        public init(value: MoneyValue?, period: TimePeriod) {
            self.value = value
            self.period = period
        }
    }

    public let id: Identifier
    public let enabled: Bool
    public let limit: PeriodicLimit?

    public init(id: Identifier, enabled: Bool, limit: PeriodicLimit?) {
        self.id = id
        self.enabled = enabled
        self.limit = limit
    }
}
