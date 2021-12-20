// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

enum BitPayError: Error {
    case unsupportedCurrencyType
    case invalidBitPayURL
    case invoiceError
    case invalidBitcoinURL
    case invalidBitcoinCashURL
}

extension BitPayInvoiceTarget {

    // MARK: - Enums

    private enum Prefix {
        static let bitpay = "bitpay.com"
        static let bitcoin = "bitcoin:?r="
        static let bitcoinCash = "bitcoincash:?r="
    }

    private static let bitpayRepository: BitPayRepositoryAPI = resolve()

    // MARK: - Public Factory

    public static func isBitcoin(_ data: String) -> Completable {
        Completable.fromCallable {
            guard data.contains(Prefix.bitcoin) else {
                throw BitPayError.invalidBitcoinURL
            }
        }
    }

    public static func isBitcoinCash(_ data: String) -> Completable {
        Completable.fromCallable {
            guard data.contains(Prefix.bitcoinCash) else {
                throw BitPayError.invalidBitcoinCashURL
            }
        }
    }

    public static func isSupportedAsset(_ asset: CryptoCurrency) -> Completable {
        Completable.fromCallable {
            guard asset.supportsBitPay else {
                throw BitPayError.unsupportedCurrencyType
            }
        }
    }

    public static func isBitPay(_ data: String) -> Completable {
        Completable.fromCallable {
            guard data.contains(Prefix.bitpay) else {
                throw BitPayError.invalidBitPayURL
            }
        }
    }

    public static func make(
        from data: String,
        asset: CryptoCurrency
    ) -> Single<BitPayInvoiceTarget> {
        isBitPay(data)
            .andThen(invoiceId(from: data))
            .flatMap { invoiceId in
                BitPayInvoiceTarget.bitpayRepository
                    .getBitPayPaymentRequest(
                        invoiceId: invoiceId,
                        currency: asset
                    )
                    .asObservable()
                    .asSingle()
            }
            .do(onError: { error in
                Logger.shared.error("\(error)")
            })
    }

    // MARK: - Private Functions

    private static func invoiceId(from data: String) -> Single<String> {
        .create { observer -> Disposable in
            let payload = data
                .replacingOccurrences(of: Prefix.bitcoin, with: "")
                .replacingOccurrences(of: Prefix.bitcoinCash, with: "")
            guard let url = URL(string: payload) else {
                observer(.error(BitPayError.invoiceError))
                return Disposables.create()
            }
            observer(.success(url.lastPathComponent))
            return Disposables.create()
        }
    }
}
