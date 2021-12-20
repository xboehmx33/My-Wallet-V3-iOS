// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

public struct StellarLedger: Equatable {
    let identifier: String
    let token: String
    let sequence: Int
    let transactionCount: Int?
    let operationCount: Int
    let closedAt: Date
    let totalCoins: String
    /// Network fee per operation in a transaction, field in minor value (stroops).
    let baseFeeInStroops: Int?
    /// Base reserve is the absolute minimum balance an account may have, field in minor value (stroops).
    let baseReserveInStroops: Int?

    public var baseFeeInXlm: CryptoValue? {
        guard let baseFeeInStroops = baseFeeInStroops else { return nil }
        return CryptoValue(amount: BigInt(baseFeeInStroops), currency: .coin(.stellar))
    }

    public var baseReserveInXlm: CryptoValue? {
        guard let baseReserveInStroops = baseReserveInStroops else { return nil }
        return CryptoValue(amount: BigInt(baseReserveInStroops), currency: .coin(.stellar))
    }

    func apply(baseFeeInStroops: Int) -> StellarLedger {
        StellarLedger(
            identifier: identifier,
            token: token,
            sequence: sequence,
            transactionCount: transactionCount,
            operationCount: operationCount,
            closedAt: closedAt,
            totalCoins: totalCoins,
            baseFeeInStroops: baseFeeInStroops,
            baseReserveInStroops: baseReserveInStroops
        )
    }
}
