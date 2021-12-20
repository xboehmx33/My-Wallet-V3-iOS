// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Foundation

public struct EthereumTransactionCandidate: Equatable {
    public enum TransferType: Equatable {
        case transfer(data: Data? = nil)
        case erc20Transfer(contract: EthereumAddress)
    }

    let to: EthereumAddress
    let gasPrice: BigUInt
    let gasLimit: BigUInt
    let value: BigUInt
    let transferType: TransferType

    init(
        to: EthereumAddress,
        gasPrice: BigUInt,
        gasLimit: BigUInt,
        value: BigUInt,
        transferType: TransferType
    ) {
        self.to = to
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.value = value
        self.transferType = transferType
    }
}
