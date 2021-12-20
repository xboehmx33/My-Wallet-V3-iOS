// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import EthereumKit
import MoneyKit
import PlatformKit
import RxSwift

struct ERC20ReceiveAddress: CryptoReceiveAddress, CryptoAssetQRMetadataProviding {

    let asset: CryptoCurrency
    let address: String
    let label: String
    let onTxCompleted: TxCompleted

    var metadata: CryptoAssetQRMetadata {
        EthereumURLPayload(address: address)!
    }

    init(
        asset: CryptoCurrency,
        address: String,
        label: String,
        onTxCompleted: @escaping TxCompleted
    ) {
        guard asset.isERC20 else {
            fatalError("Not an ERC20 Token")
        }
        self.onTxCompleted = onTxCompleted
        self.asset = asset
        self.address = address
        self.label = label
    }
}
