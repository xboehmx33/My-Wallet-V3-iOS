// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public enum InterestActivityItemEventState: String {
    case failed
    case rejected
    case processing
    case complete
    case pending
    case manualReview
    case cleared
    case refunded
    case unknown
}

public enum InterestTransactionType: String {
    case transfer
    case withdraw
    case interestEarned
    case unknown
}

public struct InterestAttributes: Decodable {
    public let address: String?
    public let confirmations: Int?
    public let hash: String?
    public let identifier: String?
    public let transactionHash: String?
    public let beneficiary: InterestBeneficiary?
}

public struct InterestBeneficiary: Decodable {
    public let user: String
    public let accountRef: String
}

public struct InterestActivityItemEvent: Equatable {
    public let value: CryptoValue
    public let cryptoCurrency: CryptoCurrency
    public let identifier: String
    public let insertedAt: Date
    public let confirmations: Int
    public let accountRef: String
    public let recipientAddress: String
    public let state: InterestActivityItemEventState
    public let type: InterestTransactionType

    public init(
        value: CryptoValue,
        cryptoCurrency: CryptoCurrency,
        identifier: String,
        insertedAt: Date,
        confirmations: Int = 0,
        accountRef: String,
        recipientAddress: String,
        state: InterestActivityItemEventState,
        type: InterestTransactionType
    ) {
        self.value = value
        self.cryptoCurrency = cryptoCurrency
        self.confirmations = confirmations
        self.accountRef = accountRef
        self.recipientAddress = recipientAddress
        self.identifier = identifier
        self.insertedAt = insertedAt
        self.state = state
        self.type = type
    }
}
