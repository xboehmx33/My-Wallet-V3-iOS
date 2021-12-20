// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import NetworkKit
import PlatformKit

public protocol TransactionDetailServiceAPI {

    /// Returns the URL for the specified address's transaction detail.
    ///
    /// - Parameter transactionHash: the hash of the transaction
    /// - Parameter cryptoCurrency: the `CryptoCurrency`
    /// - Returns: the URL for the transaction detail
    func transactionDetailURL(for transactionHash: String, cryptoCurrency: CryptoCurrency) -> String?
}

final class TransactionDetailService: TransactionDetailServiceAPI {

    private let blockchainAPI: BlockchainAPI

    init(blockchainAPI: BlockchainAPI = resolve()) {
        self.blockchainAPI = blockchainAPI
    }

    func transactionDetailURL(for transactionHash: String, cryptoCurrency: CryptoCurrency) -> String? {
        switch cryptoCurrency {
        case .coin(let model):
            switch model.code {
            case NonCustodialCoinCode.bitcoin.rawValue:
                return "\(blockchainAPI.bitcoinExplorerUrl)/tx/\(transactionHash)"
            case NonCustodialCoinCode.ethereum.rawValue:
                return "\(blockchainAPI.etherExplorerUrl)/tx/\(transactionHash)"
            case NonCustodialCoinCode.bitcoinCash.rawValue:
                return "\(blockchainAPI.bitcoinCashExplorerUrl)/tx/\(transactionHash)"
            case NonCustodialCoinCode.stellar.rawValue:
                return "\(blockchainAPI.stellarchainUrl)/tx/\(transactionHash)"
            default:
                return nil
            }
        case .erc20:
            return "\(blockchainAPI.etherExplorerUrl)/tx/\(transactionHash)"
        case .celoToken:
            return nil
        }
    }
}
