// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit

public struct OrderQuotePayload {

    let identifier: String
    let product: ProductType
    let pair: OrderPair
    let quote: OrderQuote

    /// `MoneyValue` in the `pair.destinationCurrencyType`
    let networkFee: MoneyValue
    let staticFee: MoneyValue
    let sampleDepositAddress: String
    let expiresAt: Date
    let createdAt: Date
    let updatedAt: Date

    public init(
        identifier: String,
        product: ProductType = .brokerage,
        pair: OrderPair,
        quote: OrderQuote,
        networkFee: MoneyValue,
        staticFee: MoneyValue,
        sampleDepositAddress: String,
        expiresAt: Date,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.identifier = identifier
        self.product = product
        self.pair = pair
        self.quote = quote
        self.networkFee = networkFee
        self.staticFee = staticFee
        self.sampleDepositAddress = sampleDepositAddress
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
