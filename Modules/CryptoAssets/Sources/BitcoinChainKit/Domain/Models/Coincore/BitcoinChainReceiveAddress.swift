// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift

public struct BitcoinChainReceiveAddress<Token: BitcoinChainToken>: CryptoReceiveAddress, CryptoAssetQRMetadataProviding {

    public var asset: CryptoCurrency {
        Token.coin.cryptoCurrency
    }

    public let address: String
    public let label: String
    public let onTxCompleted: TxCompleted
    public let index: Int32

    public var metadata: CryptoAssetQRMetadata {
        switch Token.coin {
        case .bitcoin:
            return BitcoinURLPayload(address: address, amount: nil, includeScheme: true)
        case .bitcoinCash:
            return BitcoinCashURLPayload(address: address, amount: nil, includeScheme: true)
        }
    }

    public init(
        address: String,
        label: String,
        onTxCompleted: @escaping TxCompleted,
        index: Int32 = 0
    ) {
        self.index = index
        self.address = address
        self.label = label
        self.onTxCompleted = onTxCompleted
    }
}
