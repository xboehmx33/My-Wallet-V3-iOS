// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public struct EthereumActivityItemEventDetails: Equatable {

    public struct Confirmation: Equatable {
        public let needConfirmation: Bool
        public let confirmations: Int
        public let requiredConfirmations: Int
        public let factor: Float
        public let status: EthereumTransactionState
    }

    public let amount: CryptoValue
    public let confirmation: Confirmation
    public let createdAt: Date
    public let data: String?
    public let fee: CryptoValue
    public let from: EthereumAddress
    public let identifier: String
    public let to: EthereumAddress

    init(transaction: EthereumHistoricalTransaction) {
        amount = transaction.amount
        createdAt = transaction.createdAt
        data = transaction.data
        fee = transaction.fee ?? .zero(currency: .coin(.ethereum))
        from = transaction.fromAddress
        identifier = transaction.transactionHash
        to = transaction.toAddress
        confirmation = Confirmation(
            needConfirmation: transaction.state == .pending,
            confirmations: transaction.confirmations,
            requiredConfirmations: EthereumHistoricalTransaction.requiredConfirmations,
            factor: Float(transaction.confirmations) / Float(EthereumHistoricalTransaction.requiredConfirmations),
            status: transaction.state
        )
    }
}
