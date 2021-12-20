// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit

public struct BitcoinCashActivityItemEventDetails: Equatable {

    public struct Confirmation: Equatable {
        public let needConfirmation: Bool
        public let confirmations: Int
        public let requiredConfirmations: Int
        public let factor: Float
    }

    public let identifier: String
    public let amount: CryptoValue
    public let from: BitcoinCashAssetAddress
    public let to: BitcoinCashAssetAddress
    public let createdAt: Date
    public let confirmation: Confirmation
    public let fee: CryptoValue

    init(transaction: BitcoinCashHistoricalTransaction) {
        self.init(
            amount: transaction.amount,
            requiredConfirmations: BitcoinCashHistoricalTransaction.requiredConfirmations,
            transactionHash: transaction.transactionHash,
            createdAt: transaction.createdAt,
            isConfirmed: transaction.isConfirmed,
            confirmations: transaction.confirmations,
            from: transaction.fromAddress,
            to: transaction.toAddress,
            fee: transaction.fee
        )
    }

    init(
        amount: CryptoValue,
        requiredConfirmations: Int,
        transactionHash: String,
        createdAt: Date,
        isConfirmed: Bool,
        confirmations: Int,
        from: BitcoinCashAssetAddress,
        to: BitcoinCashAssetAddress,
        fee: CryptoValue?
    ) {
        identifier = transactionHash
        self.createdAt = createdAt
        confirmation = .init(
            needConfirmation: !isConfirmed,
            confirmations: confirmations,
            requiredConfirmations: requiredConfirmations,
            factor: Float(confirmations) / Float(requiredConfirmations)
        )
        self.from = from
        self.to = to
        self.fee = fee ?? .zero(currency: amount.currency)
        self.amount = amount
    }
}
