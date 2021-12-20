// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit
import PlatformKit

public struct EthereumSignMessageTarget: WalletConnectTarget {

    public enum Message {
        /// The Data message to be signed.
        /// Used for `eth_sign` and `personal_sign` WalletConnect methods.
        case data(Data)
        /// The String typed data message to be signed.
        /// Used for `eth_signTypedData` WalletConnect method.
        case typedData(String)
    }

    // MARK: - Public Properties

    public let onTxCompleted: TxCompleted
    public let dAppAddress: String
    public let dAppName: String
    public let dAppLogoURL: String
    public let currencyType: CurrencyType = .crypto(.coin(.ethereum))
    public let account: String
    public let message: Message
    public var label: String {
        dAppName
    }

    var readableMessage: String {
        switch message {
        case .typedData(let typedDataJson):
            let data = Data(typedDataJson.utf8)
            let decoded = try? JSONDecoder().decode(
                TypedDataPayload.self,
                from: data
            )
            return decoded
                .flatMap { typedDataPayload in
                    typedDataPayload.message.description
                }
                ?? typedDataJson

        case .data(let data):
            return String(data: data, encoding: .utf8)
                ?? data.hexString.withHex
        }
    }

    public init(
        dAppAddress: String,
        dAppName: String,
        dAppLogoURL: String,
        account: String,
        message: Message,
        onTxCompleted: @escaping TxCompleted
    ) {
        self.onTxCompleted = onTxCompleted
        self.dAppAddress = dAppAddress
        self.dAppName = dAppName
        self.dAppLogoURL = dAppLogoURL
        self.account = account
        self.message = message
    }
}
