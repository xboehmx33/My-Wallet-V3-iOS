// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift

public struct BitcoinChainTransactionFee<Token: BitcoinChainToken>: TransactionFee, Decodable {
    public static var cryptoType: HasPathComponent {
        Token.coin.cryptoCurrency
    }

    public static var `default`: BitcoinChainTransactionFee<Token> {
        switch Token.coin {
        case .bitcoin:
            return BitcoinChainTransactionFee<Token>(
                regular: 5, priority: 11
            )
        case .bitcoinCash:
            return BitcoinChainTransactionFee<Token>(
                regular: 5,
                priority: 11
            )
        }
    }

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
        switch Token.coin {
        case .bitcoin:
            regular = CryptoValue(amount: BigInt(regularFee), currency: .coin(.bitcoin))
            priority = CryptoValue(amount: BigInt(priorityFee), currency: .coin(.bitcoin))
        case .bitcoinCash:
            regular = CryptoValue(amount: BigInt(regularFee), currency: .coin(.bitcoinCash))
            priority = CryptoValue(amount: BigInt(priorityFee), currency: .coin(.bitcoinCash))
        }
    }

    init(regular: Int, priority: Int) {
        switch Token.coin {
        case .bitcoin:
            self.regular = CryptoValue(amount: BigInt(regular), currency: .coin(.bitcoin))
            self.priority = CryptoValue(amount: BigInt(priority), currency: .coin(.bitcoin))
        case .bitcoinCash:
            self.regular = CryptoValue(amount: BigInt(regular), currency: .coin(.bitcoinCash))
            self.priority = CryptoValue(amount: BigInt(priority), currency: .coin(.bitcoinCash))
        }
    }
}
