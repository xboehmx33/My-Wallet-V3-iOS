// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureQRCodeScannerDomain
import PlatformKit

public final class WalletConnectQRCodeParser: QRCodeScannerParsing {

    // MARK: Types

    enum ScannerError: LocalizedError {
        case qrCodeIsNotWalletConnect

        var errorDescription: String? {
            switch self {
            case .qrCodeIsNotWalletConnect:
                return "Invalid QR Code."
            }
        }
    }

    // MARK: Init

    public init() {}

    // MARK: QRCodeScannerParsing

    public func parse(
        scanResult: Result<String, QRScannerError>
    ) -> AnyPublisher<QRCodeScannerResultType, QRScannerError> {
        scanResult
            .flatMap { link in
                if link.hasPrefix("wc:") {
                    return .success(.walletConnect(link))
                } else {
                    return .failure(.parserError(ScannerError.qrCodeIsNotWalletConnect))
                }
            }
            .publisher
            .eraseToAnyPublisher()
    }
}
