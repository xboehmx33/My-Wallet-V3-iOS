// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

/// A request submitted for transferring custodial funds from your custodial wallet to any non-custodial address.
public struct CustodialTransferRequest: Encodable {
    public let address: String
    public let moneyValue: MoneyValue

    enum CodingKeys: String, CodingKey {
        case address
        case currency
        case amount
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let currency = moneyValue.code
        try container.encode(address, forKey: .address)
        try container.encode(currency, forKey: .currency)
        try container.encode(moneyValue.amount.description, forKey: .amount)
    }
}
