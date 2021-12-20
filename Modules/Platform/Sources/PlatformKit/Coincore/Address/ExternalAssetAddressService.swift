// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import RxSwift

public enum CryptoReceiveAddressFactoryError: Error {
    case invalidAddress
    case unsupportedAsset
}

/// A service that creates a `CryptoReceiveAddress` of the given `CryptoCurrency`.
/// Use this when you don't already have access to the given `CryptoCurrency`'s `CryptoAsset`.
public protocol ExternalAssetAddressServiceAPI {

    typealias TxCompleted = (TransactionResult) -> Completable

    func makeExternalAssetAddress(
        asset: CryptoCurrency,
        address: String,
        label: String,
        onTxCompleted: @escaping TxCompleted
    ) -> Result<CryptoReceiveAddress, CryptoReceiveAddressFactoryError>
}

final class ExternalAssetAddressService: ExternalAssetAddressServiceAPI {

    private let coincore: CoincoreAPI

    init(coincore: CoincoreAPI = resolve()) {
        self.coincore = coincore
    }

    func makeExternalAssetAddress(
        asset: CryptoCurrency,
        address: String,
        label: String,
        onTxCompleted: @escaping (TransactionResult) -> Completable
    ) -> Result<CryptoReceiveAddress, CryptoReceiveAddressFactoryError> {
        coincore[asset]
            .parse(
                address: address,
                label: label,
                onTxCompleted: onTxCompleted
            )
    }
}
