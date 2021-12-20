// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

public struct EthereumTransactionFee {

    public enum FeeLevel {
        case regular
        case priority
    }

    static let `default` = EthereumTransactionFee(
        regular: 90,
        priority: 110,
        gasLimit: 21000,
        gasLimitContract: 75000
    )

    let regular: CryptoValue
    let priority: CryptoValue
    let gasLimit: Int
    let gasLimitContract: Int

    init(regular: Int, priority: Int, gasLimit: Int, gasLimitContract: Int) {
        self.regular = CryptoValue.ether(gwei: BigInt(regular))
        self.priority = CryptoValue.ether(gwei: BigInt(priority))
        self.gasLimit = gasLimit
        self.gasLimitContract = gasLimitContract
    }

    public func fee(feeLevel: FeeLevel) -> CryptoValue {
        switch feeLevel {
        case .regular:
            return regular
        case .priority:
            return priority
        }
    }

    public func absoluteFee(with feeLevel: FeeLevel, isContract: Bool) -> CryptoValue {
        let price = fee(feeLevel: feeLevel).amount
        let gasLimit = BigInt(isContract ? gasLimitContract : gasLimit)
        let amount = price * gasLimit
        return CryptoValue.create(minor: amount, currency: .coin(.ethereum))
    }
}

extension CryptoValue {

    static func ether(gwei: BigInt) -> CryptoValue {
        let wei = gwei * BigInt(1e9)
        return CryptoValue(amount: wei, currency: .coin(.ethereum))
    }
}
