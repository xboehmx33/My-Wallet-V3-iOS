// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit
import PlatformKit

public struct EthereumSendTransactionTarget: WalletConnectTarget {

    public enum Method {
        case sign
        case send
    }

    // MARK: - Public Properties

    public let onTxCompleted: TxCompleted
    public let currencyType: CurrencyType = .crypto(.coin(.ethereum))
    public var label: String {
        dAppName
    }

    // MARK: - Properties

    let method: Method
    let dAppAddress: String
    let dAppName: String
    let dAppLogoURL: String
    let transaction: EthereumJsonRpcTransaction

    // MARK: - Init

    public init(
        dAppAddress: String,
        dAppName: String,
        dAppLogoURL: String,
        transaction: EthereumJsonRpcTransaction,
        method: Method,
        onTxCompleted: @escaping TxCompleted
    ) {
        self.onTxCompleted = onTxCompleted
        self.dAppAddress = dAppAddress
        self.dAppName = dAppName
        self.dAppLogoURL = dAppLogoURL
        self.transaction = transaction
        self.method = method
    }
}
