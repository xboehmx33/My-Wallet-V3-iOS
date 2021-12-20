// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import PlatformKit
import RxSwift

public enum CryptoTargetQRCodeParserTarget {
    case address(CryptoReceiveAddress)
    case bitpay(String)
}

public protocol CryptoTargetPayloadFactoryAPI {
    func create(
        fromString string: String?,
        asset: CryptoCurrency
    ) -> AnyPublisher<CryptoTargetQRCodeParserTarget, CryptoTargetPayloadError>
}

public enum CryptoTargetPayloadError: Error {
    case invalidStringData
    case bitPay(Error)
}

final class CryptoTargetPayloadFactory: CryptoTargetPayloadFactoryAPI {

    // MARK: - Private Properties

    private let receiveAddressService: ExternalAssetAddressServiceAPI

    // MARK: - Init

    init(receiveAddressService: ExternalAssetAddressServiceAPI = resolve()) {
        self.receiveAddressService = receiveAddressService
    }

    // MARK: - CryptoTargetPayloadFactoryAPI

    func create(
        fromString string: String?,
        asset: CryptoCurrency
    ) -> AnyPublisher<CryptoTargetQRCodeParserTarget, CryptoTargetPayloadError> {
        guard let data = string else {
            return .failure(CryptoTargetPayloadError.invalidStringData)
        }
        let metadata = makeCryptoQRMetaData(fromString: data, asset: asset)
        return BitPayInvoiceTarget
            // Check if the data is a BitPay payload.
            .isBitPay(data)
            // Check if the asset is a supported asset for BitPay.
            .andThen(BitPayInvoiceTarget.isSupportedAsset(asset))
            // Return the BitPay data
            .andThen(Single.just(.bitpay(data)))
            .asPublisher()
            .catch { error -> AnyPublisher<CryptoTargetQRCodeParserTarget, CryptoTargetPayloadError> in
                guard let bitpayError = error as? BitPayError else {
                    return .failure(.invalidStringData)
                }
                switch bitpayError {
                // If the BitPay URL is valid but
                // is invalid for either BTC or BCH
                // we throw an error.
                case .unsupportedCurrencyType,
                     .invalidBitcoinURL,
                     .invalidBitcoinCashURL,
                     .invoiceError:
                    return .failure(.bitPay(bitpayError))
                // If the BitPay URL is invalid,
                // we return the data, as it's likely a regular
                // receive address.
                case .invalidBitPayURL:
                    return metadata
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Functions

    private func makeCryptoQRMetaData(
        fromString string: String,
        asset: CryptoCurrency
    ) -> AnyPublisher<CryptoTargetQRCodeParserTarget, CryptoTargetPayloadError> {
        receiveAddressService
            .makeExternalAssetAddress(
                asset: asset,
                address: string,
                label: string,
                onTxCompleted: { _ in .empty() }
            )
            .map(CryptoTargetQRCodeParserTarget.address)
            .replaceError(with: CryptoTargetPayloadError.invalidStringData)
            .publisher
            .eraseToAnyPublisher()
    }
}
