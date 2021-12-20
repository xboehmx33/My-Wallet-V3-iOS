// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import BitcoinChainKit
import MoneyKit
import PlatformKit

public class BitcoinCashHistoricalTransaction: Decodable, BitcoinChainHistoricalTransactionResponse {

    public static let requiredConfirmations: Int = 3

    // MARK: - Output

    public struct Output: Decodable {
        let spent: Bool
        let change: Bool
        let amount: CryptoValue
        let address: String

        struct Xpub: Codable {
            let value: String

            enum CodingKeys: String, CodingKey {
                case value = "m"
            }
        }

        enum CodingKeys: String, CodingKey {
            case spent
            case xpub
            case amount = "value"
            case address = "addr"
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            spent = try values.decode(Bool.self, forKey: .spent)
            let satoshis = try values.decode(Int.self, forKey: .amount)
            amount = CryptoValue(amount: BigInt(satoshis), currency: .coin(.bitcoinCash))
            address = try values.decode(String.self, forKey: .address)
            let xpub = try values.decodeIfPresent(Xpub.self, forKey: .xpub)
            change = xpub != nil
        }
    }

    // MARK: - Input

    public struct Input: Decodable {
        let previousOutput: Output

        enum CodingKeys: String, CodingKey {
            case previousOutput = "prev_out"
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            previousOutput = try values.decode(Output.self, forKey: .previousOutput)
        }
    }

    // MARK: - Public Properties

    /**
     The transaction identifier, used for equality checking and backend calls.

     - Note: For Bitcoin Cash, this is identical to `transactionHash`.
     */
    public var identifier: String {
        transactionHash
    }

    public let direction: Direction
    public let fromAddress: BitcoinCashAssetAddress
    public let toAddress: BitcoinCashAssetAddress
    public let amount: CryptoValue
    public let transactionHash: String
    public let createdAt: Date
    public let fee: CryptoValue?
    public let note: String?
    public let inputs: [Input]
    public let outputs: [Output]
    public let blockHeight: Int?
    public var confirmations: Int = 0
    public var isConfirmed: Bool {
        confirmations >= BitcoinCashHistoricalTransaction.requiredConfirmations
    }

    enum CodingKeys: String, CodingKey {
        case identifier = "hash"
        case amount = "result"
        case blockHeight = "block_height"
        case time
        case fee
        case inputs
        case outputs = "out"
    }

    // MARK: - Decodable

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let amount = try values.decode(Int64.self, forKey: .amount)
        let value = BigInt(amount)
        self.amount = CryptoValue.create(minor: abs(value), currency: .coin(.bitcoinCash))
        direction = value.sign == .minus ? .credit : .debit
        transactionHash = try values.decode(String.self, forKey: .identifier)
        blockHeight = try values.decodeIfPresent(Int.self, forKey: .blockHeight)
        createdAt = try values.decode(Date.self, forKey: .time)
        inputs = try values.decode([Input].self, forKey: .inputs)
        let feeValue = try values.decode(Int.self, forKey: .fee)
        fee = CryptoValue(amount: BigInt(feeValue), currency: .coin(.bitcoinCash))
        outputs = try values.decode([Output].self, forKey: .outputs)

        guard let destinationOutput = outputs.first else {
            throw DecodingError.dataCorruptedError(
                forKey: .outputs,
                in: values,
                debugDescription: "Expected a destination output"
            )
        }

        guard let fromOutput = inputs.first?.previousOutput else {
            throw DecodingError.dataCorruptedError(
                forKey: .outputs,
                in: values,
                debugDescription: "Expected a from output"
            )
        }
        toAddress = BitcoinCashAssetAddress(publicKey: destinationOutput.address)
        fromAddress = BitcoinCashAssetAddress(publicKey: fromOutput.address)

        note = nil
    }

    // MARK: - BitcoinChainHistoricalTransaction

    public func apply(latestBlockHeight: Int) {
        confirmations = (latestBlockHeight - (blockHeight ?? latestBlockHeight)) + 1
    }
}
