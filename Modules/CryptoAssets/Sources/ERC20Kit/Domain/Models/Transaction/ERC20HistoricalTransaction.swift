// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import EthereumKit
import MoneyKit
import PlatformKit
import RxSwift

public struct ERC20HistoricalTransaction: Hashable {

    /**
     The transaction identifier, used for equality checking and backend calls.

     - Note: For ERC20 assets, this is identical to `transactionHash`.
     */
    public var identifier: String {
        transactionHash
    }

    public var fromAddress: EthereumAddress
    public var toAddress: EthereumAddress
    public var direction: Direction
    public var amount: CryptoValue
    public var transactionHash: String
    public var createdAt: Date
    public var fee: CryptoValue?
    public var historicalFiatValue: FiatValue?
    public var note: String?

    public init(
        fromAddress: EthereumAddress,
        toAddress: EthereumAddress,
        direction: Direction,
        amount: CryptoValue,
        transactionHash: String,
        createdAt: Date,
        fee: CryptoValue?,
        note: String?
    ) {
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.direction = direction
        self.amount = amount
        self.transactionHash = transactionHash
        self.createdAt = createdAt
        self.fee = fee
        self.note = note
    }

    init(response: ERC20TransfersResponse.Transfer, cryptoCurrency: CryptoCurrency, source: EthereumAddress) {
        let createdAt: Date
        if let timeSinceEpoch = Double(response.timestamp) {
            createdAt = Date(timeIntervalSince1970: timeSinceEpoch)
        } else {
            createdAt = Date()
        }
        let fromAddress = EthereumAddress(address: response.from)!
        self.init(
            fromAddress: fromAddress,
            toAddress: EthereumAddress(address: response.to)!,
            direction: fromAddress == source ? .credit : .debit,
            amount: CryptoValue.create(minor: response.value, currency: cryptoCurrency) ?? .zero(currency: cryptoCurrency),
            transactionHash: response.transactionHash,
            createdAt: createdAt,
            fee: nil,
            note: nil
        )
    }
}
