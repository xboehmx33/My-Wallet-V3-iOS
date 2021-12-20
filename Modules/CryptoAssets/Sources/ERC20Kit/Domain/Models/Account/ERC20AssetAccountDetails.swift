// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public struct ERC20AssetAccountDetails: Equatable {
    public let account: ERC20AssetAccount
    public let balance: CryptoValue
}
