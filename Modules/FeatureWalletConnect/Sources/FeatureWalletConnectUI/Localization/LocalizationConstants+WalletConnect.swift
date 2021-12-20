// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization

extension LocalizationConstants {
    enum WalletConnect {
        static let confirm = NSLocalizedString("Confirm", comment: "confirm")

        static let dAppWantsToConnect = NSLocalizedString(
            "%@ wants to connect.",
            comment: "WalletConnect: connection authorization with dApp name"
        )

        static let dAppConnectionSuccess = NSLocalizedString(
            "%@ is now connected to your wallet.",
            comment: "WalletConnect: connection confirmation with dApp name"
        )

        static let dAppConnectionFail = NSLocalizedString(
            "%@ connection was rejected.",
            comment: "WalletConnect: connection failed with dApp name"
        )

        static let dAppConnectionFailMessage = NSLocalizedString(
            "Go back to your browser and try again.",
            comment: "WalletConnect: connection fail instruction message"
        )

        static let connectedAppsCount = NSLocalizedString(
            "%@ Connected Apps",
            comment: "WalletConnect: number of connected dApps"
        )

        static let connectedAppCount = NSLocalizedString(
            "1 Connected App",
            comment: "WalletConnect: 1 connected dApp"
        )

        static let disconnect = NSLocalizedString(
            "Disconnect",
            comment: "WalletConnect: disconnect button title"
        )
    }
}
