// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit

/// A `CryptoReceiveAddress & CryptoAssetQRMetadataProviding` that doesn't know how to validate the asset/address and assumes it is correct.
struct PlainCryptoReceiveAddress: CryptoReceiveAddress, CryptoAssetQRMetadataProviding {
    let address: String
    let asset: CryptoCurrency
    let label: String
    var metadata: CryptoAssetQRMetadata {
        PlainCryptoAssetQRMetadata(address: address, cryptoCurrency: asset)
    }

    init(address: String, asset: CryptoCurrency, label: String) {
        self.address = address
        self.asset = asset
        self.label = label
    }
}
