// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

public struct StellarTransactionFee: TransactionFee, Decodable {

    enum CodingKeys: String, CodingKey {
        case regular
        case priority
        case limits
    }

    public static var cryptoType: HasPathComponent = CryptoCurrency.coin(.stellar)
    public static let `default` = StellarTransactionFee(
        regular: 100,
        priority: 10000
    )

    public var regular: CryptoValue
    public var priority: CryptoValue

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let regularFee = try values.decode(Int.self, forKey: .regular)
        let priorityFee = try values.decode(Int.self, forKey: .priority)
        regular = CryptoValue(amount: BigInt(regularFee), currency: .coin(.stellar))
        priority = CryptoValue(amount: BigInt(priorityFee), currency: .coin(.stellar))
    }

    public init(regular: Int, priority: Int) {
        self.regular = CryptoValue(amount: BigInt(regular), currency: .coin(.stellar))
        self.priority = CryptoValue(amount: BigInt(priority), currency: .coin(.stellar))
    }
}
