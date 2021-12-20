// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
@testable import EthereumKit
@testable import EthereumKitMock
@testable import MoneyKit
import PlatformKit
import XCTest

final class EthereumTransactionCandidateCostedTests: XCTestCase {

    func test_build_transaction() {
        let toAddress = EthereumAddress(address: "0x3535353535353535353535353535353535353535")!
        let value = BigUInt("0.01658472", decimals: CryptoCurrency.coin(.ethereum).precision)!
        let nonce = MockEthereumWalletTestData.Transaction.nonce
        let gasPrice = MockEthereumWalletTestData.Transaction.gasPrice
        let gasLimit = MockEthereumWalletTestData.Transaction.gasLimit

        let transaction = EthereumTransactionCandidate(
            to: toAddress,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            value: value,
            transferType: .transfer()
        )

        let result = EthereumTransactionCandidateCosted.create(
            transaction: transaction,
            nonce: nonce
        )

        guard case .success(let costed) = result else {
            XCTFail("The transaction should be built successfully")
            return
        }

        let input = costed.transaction
        XCTAssertEqual(input.gasLimit.hexString, "5208")
        XCTAssertEqual(input.gasPrice.hexString, "028fa6ae00")
        XCTAssertEqual(input.nonce.hexString, "09")
        XCTAssertEqual(input.toAddress, "0x3535353535353535353535353535353535353535")
        XCTAssertEqual(input.transaction.transfer.amount.hexString, "3aebb7084ca000")
        XCTAssertEqual(input.transaction.transfer.data.hexString, "")
        XCTAssertEqual(input.chainID.hexString, "01")
    }

    func test_build_transaction_failure_gas_limit() {
        let toAddress = EthereumAddress(address: "0x3535353535353535353535353535353535353535")!
        let value = BigUInt("0.01658472", decimals: CryptoCurrency.coin(.ethereum).precision)!
        let nonce = MockEthereumWalletTestData.Transaction.nonce
        let gasPrice: BigUInt = MockEthereumWalletTestData.Transaction.gasPrice
        let gasLimit: BigUInt = 0

        let transaction = EthereumTransactionCandidate(
            to: toAddress,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            value: value,
            transferType: .transfer()
        )

        let result = EthereumTransactionCandidateCosted.create(
            transaction: transaction,
            nonce: nonce
        )

        guard case .failure(let error) = result else {
            XCTFail("The transaction should not be built")
            return
        }
        XCTAssertEqual(error, EthereumKitValidationError.noGasLimit)
    }

    func test_build_transaction_failure_gas_price() {
        let toAddress = EthereumAddress(address: "0x3535353535353535353535353535353535353535")!
        let value = BigUInt("0.01658472", decimals: CryptoCurrency.coin(.ethereum).precision)!
        let nonce = MockEthereumWalletTestData.Transaction.nonce
        let gasPrice: BigUInt = 0
        let gasLimit = MockEthereumWalletTestData.Transaction.gasLimit

        let transaction = EthereumTransactionCandidate(
            to: toAddress,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            value: value,
            transferType: .transfer()
        )

        let result = EthereumTransactionCandidateCosted.create(
            transaction: transaction,
            nonce: nonce
        )

        guard case .failure(let error) = result else {
            XCTFail("The transaction should not be built")
            return
        }
        XCTAssertEqual(error, EthereumKitValidationError.noGasPrice)
    }
}
