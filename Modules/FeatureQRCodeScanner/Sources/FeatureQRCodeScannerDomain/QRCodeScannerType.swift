// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit

public enum QRCodeScannerType {
    case deepLink
    case cryptoTarget(sourceAccount: CryptoAccount?)
    case walletConnect
}

public enum QRCodeScannerResultType {
    case cryptoTarget(_ target: QRCodeParserTarget)
    case secureChannel(_ message: String)
    case deepLink(_ link: String)
    case walletConnect(_ url: String)
}
