// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxSwift

struct StellarReceiveAddress: CryptoReceiveAddress, CryptoAssetQRMetadataProviding {

    let asset: CryptoCurrency = .coin(.stellar)
    let address: String
    let label: String
    let memo: String?
    let onTxCompleted: TxCompleted

    var metadata: CryptoAssetQRMetadata {
        StellarURLPayload(address: address, amount: nil, memo: memo)
    }

    init(
        address: String,
        label: String,
        memo: String? = nil,
        onTxCompleted: @escaping TxCompleted = { _ in .empty() }
    ) {
        self.address = address
        self.label = label
        self.memo = memo
        self.onTxCompleted = onTxCompleted
    }
}
