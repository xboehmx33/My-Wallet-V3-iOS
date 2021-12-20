// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import EthereumKit
import MoneyKit

extension AssetModel {
    var contractAddress: EthereumAddress? {
        switch kind {
        case .erc20(let contractAddress):
            return EthereumAddress(address: contractAddress)
        default:
            return nil
        }
    }
}
