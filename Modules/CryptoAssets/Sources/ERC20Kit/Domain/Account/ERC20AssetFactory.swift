// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

final class ERC20AssetFactory: ERC20AssetFactoryAPI {
    func erc20Asset(erc20AssetModel: AssetModel) -> CryptoAsset {
        ERC20Asset(erc20Token: erc20AssetModel)
    }
}
