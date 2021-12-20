// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

public struct BitcoinCashTransactionFee: TransactionFee, Decodable {

    public static var cryptoType: HasPathComponent = CryptoCurrency.coin(.bitcoinCash)
    public static let `default` = BitcoinCashTransactionFee(
        regular: 5,
        priority: 11
    )

    public var regular: CryptoValue
    public var priority: CryptoValue

    enum CodingKeys: String, CodingKey {
        case regular
        case priority
        case limits
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let regularFee = try values.decode(Int.self, forKey: .regular)
        let priorityFee = try values.decode(Int.self, forKey: .priority)
        regular = CryptoValue(amount: BigInt(regularFee), currency: .coin(.bitcoinCash))
        priority = CryptoValue(amount: BigInt(priorityFee), currency: .coin(.bitcoinCash))
    }

    init(regular: Int, priority: Int) {
        self.regular = CryptoValue(amount: BigInt(regular), currency: .coin(.bitcoinCash))
        self.priority = CryptoValue(amount: BigInt(priority), currency: .coin(.bitcoinCash))
    }
}
