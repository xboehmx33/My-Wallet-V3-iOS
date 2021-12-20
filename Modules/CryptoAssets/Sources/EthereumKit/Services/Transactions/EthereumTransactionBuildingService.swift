// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import FeatureTransactionDomain
import Foundation
import MoneyKit
import PlatformKit
import RxSwift

public protocol EthereumTransactionBuildingServiceAPI {
    func buildTransaction(
        amount: MoneyValue,
        to address: EthereumAddress,
        feeLevel: FeeLevel,
        fee: EthereumTransactionFee,
        contractAddress: EthereumAddress?
    ) -> Result<EthereumTransactionCandidate, Never>

    func buildTransaction(
        amount: MoneyValue,
        to address: EthereumAddress,
        gasPrice: BigUInt,
        gasLimit: BigUInt,
        transferType: EthereumTransactionCandidate.TransferType
    ) -> Result<EthereumTransactionCandidate, Never>
}

final class EthereumTransactionBuildingService: EthereumTransactionBuildingServiceAPI {

    func buildTransaction(
        amount: MoneyValue,
        to address: EthereumAddress,
        feeLevel: FeeLevel,
        fee: EthereumTransactionFee,
        contractAddress: EthereumAddress?
    ) -> Result<EthereumTransactionCandidate, Never> {
        let isContract = contractAddress != nil
        let gasPrice = BigUInt(
            fee.fee(feeLevel: feeLevel.ethereumFeeLevel).amount
        )
        let gasLimit = BigUInt(
            isContract ? fee.gasLimitContract : fee.gasLimit
        )
        let transferType: EthereumTransactionCandidate.TransferType = contractAddress
            .flatMap { .erc20Transfer(contract: $0) }
            ?? .transfer()
        return buildTransaction(
            amount: amount,
            to: address,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            transferType: transferType
        )
    }

    func buildTransaction(
        amount: MoneyValue,
        to address: EthereumAddress,
        gasPrice: BigUInt,
        gasLimit: BigUInt,
        transferType: EthereumTransactionCandidate.TransferType
    ) -> Result<EthereumTransactionCandidate, Never> {
        .success(
            EthereumTransactionCandidate(
                to: address,
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                value: BigUInt(amount.amount),
                transferType: transferType
            )
        )
    }
}

extension FeeLevel {
    public var ethereumFeeLevel: EthereumTransactionFee.FeeLevel {
        switch self {
        case .custom, .none, .regular:
            return .regular
        case .priority:
            return .priority
        }
    }
}
