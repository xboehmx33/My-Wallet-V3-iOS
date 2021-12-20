// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Foundation
import MoneyKit

public protocol HasPathComponent {
    var pathComponent: String { get }
}

extension CryptoCurrency: HasPathComponent {
    public var pathComponent: String {
        code.lowercased()
    }
}

public protocol TransactionFee {
    static var cryptoType: HasPathComponent { get }
    static var `default`: Self { get }

    var regular: CryptoValue { get }
    var priority: CryptoValue { get }
}
