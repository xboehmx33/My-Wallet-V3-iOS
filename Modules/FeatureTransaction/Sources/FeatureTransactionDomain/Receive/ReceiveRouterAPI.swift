// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public protocol ReceiveRouterAPI: AnyObject {
    func presentReceiveScreen(for account: BlockchainAccount)
    func presentKYCScreen()
    func shareDetails(for metadata: CryptoAssetQRMetadata, currencyType: CurrencyType)
}
