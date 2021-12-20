// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit
import PlatformKit

public struct EthereumRawTransactionTarget: WalletConnectTarget {

    // MARK: - Public Properties

    public let onTxCompleted: TxCompleted
    public let currencyType: CurrencyType = .crypto(.coin(.ethereum))
    public var label: String {
        dAppName
    }

    // MARK: - Properties

    let dAppAddress: String
    let dAppName: String
    let dAppLogoURL: String
    let rawTransaction: Data

    // MARK: - Init

    public init(
        dAppAddress: String,
        dAppName: String,
        dAppLogoURL: String,
        rawTransaction: Data,
        onTxCompleted: @escaping TxCompleted
    ) {
        self.onTxCompleted = onTxCompleted
        self.dAppAddress = dAppAddress
        self.dAppName = dAppName
        self.dAppLogoURL = dAppLogoURL
        self.rawTransaction = rawTransaction
    }
}
