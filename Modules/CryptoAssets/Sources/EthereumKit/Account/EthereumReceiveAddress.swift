// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxSwift

struct EthereumReceiveAddress: CryptoReceiveAddress, CryptoAssetQRMetadataProviding {

    let asset: CryptoCurrency = .coin(.ethereum)
    let address: String
    let label: String
    let onTxCompleted: TxCompleted

    var metadata: CryptoAssetQRMetadata {
        EthereumURLPayload(address: address)!
    }

    init(address: String, label: String, onTxCompleted: @escaping TxCompleted) {
        self.address = address
        self.label = label
        self.onTxCompleted = onTxCompleted
    }
}
