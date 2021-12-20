// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit

/// A `CryptoAssetQRMetadata` that doesn't know how to validate the asset/address and assumes it is correct.
struct PlainCryptoAssetQRMetadata: CryptoAssetQRMetadata {
    let address: String
    let amount: String? = nil
    let cryptoCurrency: CryptoCurrency
    let includeScheme: Bool = false
    var absoluteString: String {
        address
    }
}
