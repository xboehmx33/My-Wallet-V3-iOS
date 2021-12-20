// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import EthereumKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift

final class ERC20ExternalAssetAddressFactory: ExternalAssetAddressFactory {

    private let asset: CryptoCurrency

    init(asset: CryptoCurrency) {
        self.asset = asset
    }

    func makeExternalAssetAddress(
        address: String,
        label: String,
        onTxCompleted: @escaping TxCompleted
    ) -> Result<CryptoReceiveAddress, CryptoReceiveAddressFactoryError> {
        guard EthereumAddress(address: address) != nil else {
            return .failure(.invalidAddress)
        }
        return .success(
            ERC20ReceiveAddress(
                asset: asset,
                address: address,
                label: address,
                onTxCompleted: { _ in Completable.empty() }
            )
        )
    }
}
