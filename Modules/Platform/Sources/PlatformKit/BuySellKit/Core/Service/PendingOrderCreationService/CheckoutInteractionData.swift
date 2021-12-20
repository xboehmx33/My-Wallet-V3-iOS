// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public struct CheckoutInteractionData {
    public let creationDate: Date?
    public let fee: MoneyValue
    public let amount: MoneyValue
    public let exchangeRate: MoneyValue?
    public let card: CardData?
    public let bankTransferData: LinkedBankData?
    public let orderId: String
    public let paymentMethod: PaymentMethod.MethodType

    public init(
        creationDate: Date?,
        fee: MoneyValue,
        amount: MoneyValue,
        exchangeRate: MoneyValue?,
        card: CardData?,
        bankTransferData: LinkedBankData?,
        orderId: String,
        paymentMethod: PaymentMethod.MethodType
    ) {
        self.creationDate = creationDate
        self.fee = fee
        self.amount = amount
        self.exchangeRate = exchangeRate
        self.card = card
        self.bankTransferData = bankTransferData
        self.orderId = orderId
        self.paymentMethod = paymentMethod
    }
}
