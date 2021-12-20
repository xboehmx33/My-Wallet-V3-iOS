// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

extension CryptoCurrency {
    var contractAddress: String? {
        assetModel.contractAddress?.publicKey
    }
}
