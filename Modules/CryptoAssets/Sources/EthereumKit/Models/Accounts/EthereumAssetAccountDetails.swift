// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public struct EthereumAssetAccountDetails: Equatable {

    public let account: EthereumWalletAccount
    public let balance: CryptoValue
    public let nonce: UInt64

    public init(account: EthereumWalletAccount, balance: CryptoValue, nonce: UInt64) {
        self.account = account
        self.balance = balance
        self.nonce = nonce
    }
}
