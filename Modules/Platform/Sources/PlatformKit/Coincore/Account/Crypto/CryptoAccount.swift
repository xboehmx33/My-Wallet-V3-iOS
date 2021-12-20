// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import RxSwift
import ToolKit

public protocol CryptoAccount: SingleAccount {
    var asset: CryptoCurrency { get }
    var isBitPaySupported: Bool { get }
}

extension CryptoAccount {

    public var isBitPaySupported: Bool {
        false
    }

    public var currencyType: CurrencyType {
        asset.currencyType
    }
}
