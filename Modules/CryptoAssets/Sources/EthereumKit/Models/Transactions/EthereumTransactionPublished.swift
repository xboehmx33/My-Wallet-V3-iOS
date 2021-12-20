// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import PlatformKit

public enum EthereumTransactionPublishedError: Error {
    case invalidResponseHash
}

public struct EthereumTransactionPublished: Equatable {

    /// The transaction hash of the published transaction.
    public let transactionHash: String

    init(transactionHash: String) {
        self.transactionHash = transactionHash
    }

    /// Creates a EthereumTransactionPublished.
    ///
    /// This factory method checks that the response transaction hash (`responseHash`) does match the given
    ///  `EthereumTransactionEncoded` transaction hash.
    static func create(
        transaction: EthereumTransactionEncoded,
        responseHash: String
    ) -> Result<EthereumTransactionPublished, EthereumTransactionPublishedError> {
        guard transaction.transactionHash == responseHash else {
            return .failure(.invalidResponseHash)
        }
        return .success(.init(transactionHash: transaction.transactionHash))
    }
}
