// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

/// An `Event` has a `Status` indicating
/// whether it is complete or not, a `type`,
/// and an amount associated with the `Event`.
public struct TransactionalActivityItemEvent {

    public enum EventStatus {
        public struct Confirmations {
            /// How many confirmations have taken place
            public let current: Int
            /// The total number of confirmations required
            public let total: Int

            public init(current: Int, total: Int) {
                self.current = current
                self.total = total
            }
        }

        /// The event is pending confirmation
        case pending(confirmations: Confirmations)
        /// The event has completed
        case complete
    }

    public enum EventType {
        /// Send transaction
        case send
        /// Transaction was received
        case receive
    }

    public let creationDate: Date

    /**
     The transaction identifier, used for equality checking and backend calls.

     - Note: This is identical to `transactionHash` for all crypto assets, except Stellar. See `StellarHistoricalTransaction` for more info.
     */
    public let identifier: String

    public let status: EventStatus
    public let type: EventType
    public let amount: CryptoValue
    public let fee: CryptoValue

    /// The transaction hash, used in Explorer URLs.
    public let transactionHash: String

    public var currency: CryptoCurrency {
        amount.currency
    }

    public init(
        identifier: String,
        transactionHash: String,
        creationDate: Date,
        status: EventStatus,
        type: EventType,
        amount: CryptoValue,
        fee: CryptoValue?
    ) {
        self.identifier = identifier
        self.transactionHash = transactionHash
        self.creationDate = creationDate
        self.status = status
        self.type = type
        self.amount = amount
        self.fee = fee ?? .zero(currency: amount.currency)
    }
}

extension TransactionalActivityItemEvent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
