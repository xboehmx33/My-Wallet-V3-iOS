// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit

public protocol AssetAddress {
    var publicKey: String { get }
    var cryptoCurrency: CryptoCurrency { get }
}
