// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization

extension LocalizationConstants {
    enum QRCodeScanner {
        static let connectedDapps = NSLocalizedString(
            "%@ Connected Apps",
            comment: "Number of connected dApps with WalletConnect"
        )

        static let connectedDApp = NSLocalizedString(
            "1 Connected App",
            comment: "When only 1 connected dApp with WalletConnect"
        )
    }
}
