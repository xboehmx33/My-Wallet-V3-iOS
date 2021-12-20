// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

public enum EthereumTransactionState: String, CaseIterable, Codable {
    case confirmed = "CONFIRMED"
    case pending = "PENDING"
    case replaced = "REPLACED"
}

public struct EthereumHistoricalTransaction {
    public static let requiredConfirmations: Int = 12

    public var fromAddress: EthereumAddress
    public var toAddress: EthereumAddress
    public var identifier: String
    public var direction: Direction
    public var amount: CryptoValue
    public var transactionHash: String
    public var createdAt: Date
    public var fee: CryptoValue?
    public var note: String?
    public var confirmations: Int
    public var state: EthereumTransactionState
    public let data: String?

    public init(
        identifier: String,
        fromAddress: EthereumAddress,
        toAddress: EthereumAddress,
        direction: Direction,
        amount: CryptoValue,
        transactionHash: String,
        createdAt: Date,
        fee: CryptoValue?,
        note: String?,
        confirmations: Int,
        data: String?,
        state: EthereumTransactionState
    ) {
        self.identifier = identifier
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.direction = direction
        self.amount = amount
        self.transactionHash = transactionHash
        self.createdAt = createdAt
        self.fee = fee
        self.note = note
        self.confirmations = confirmations
        self.state = state
        self.data = data
    }

    public init(
        response: EthereumHistoricalTransactionResponse,
        note: String? = nil,
        accountAddress: String,
        latestBlock: BigInt
    ) {
        identifier = response.hash
        fromAddress = EthereumAddress(address: response.from)!
        toAddress = EthereumAddress(address: response.to)!
        direction = EthereumHistoricalTransaction.direction(
            to: response.to,
            from: response.from,
            accountAddress: accountAddress
        )
        amount = CryptoValue(amount: BigInt(response.value) ?? 0, currency: .coin(.ethereum))
        transactionHash = response.hash
        createdAt = response.createdAt
        fee = EthereumHistoricalTransaction.fee(
            gasPrice: response.gasPrice,
            gasUsed: response.gasUsed
        )
        self.note = note
        confirmations = EthereumHistoricalTransaction.confirmations(
            latestBlock: latestBlock,
            blockNumber: response.blockNumber
        )
        state = response.state
        data = response.data
    }

    private static func created(timestamp: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    private static func direction(to: String, from: String, accountAddress: String) -> Direction {
        let incoming = to.lowercased() == accountAddress.lowercased()
        let outgoing = from.lowercased() == accountAddress.lowercased()
        if incoming, outgoing {
            return .transfer
        }
        if incoming {
            return .debit
        }
        return .credit
    }

    private static func fee(gasPrice: String, gasUsed: String?) -> CryptoValue {
        let ethereum = CryptoCurrency.coin(.ethereum)
        guard let gasUsed = gasUsed else {
            return .zero(currency: ethereum)
        }
        guard let gasPrice = BigInt(gasPrice),
              let gasUsed = BigInt(gasUsed)
        else {
            return .zero(currency: ethereum)
        }
        return CryptoValue
            .create(
                minor: gasPrice * gasUsed,
                currency: ethereum
            )
    }

    private static func confirmations(latestBlock: BigInt, blockNumber: String?) -> Int {
        blockNumber
            .flatMap { BigInt($0) }
            .flatMap { blockNumber in
                let difference = (latestBlock - blockNumber) + 1
                let confirmations = max(difference, 0)
                return Int(confirmations)
            }
            ?? 0
    }
}

extension EthereumHistoricalTransaction: Comparable {
    public static func < (lhs: EthereumHistoricalTransaction, rhs: EthereumHistoricalTransaction) -> Bool {
        lhs.createdAt < rhs.createdAt
    }
}

extension EthereumHistoricalTransaction: Equatable {
    public static func == (lhs: EthereumHistoricalTransaction, rhs: EthereumHistoricalTransaction) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
