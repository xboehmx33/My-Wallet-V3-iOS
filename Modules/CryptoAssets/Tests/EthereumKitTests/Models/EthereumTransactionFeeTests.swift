// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import EthereumKit
import MoneyKit
import PlatformKit
import XCTest

class EthereumTransactionFeeTests: XCTestCase {

    var sut: EthereumTransactionFee!

    override func setUp() {
        sut = EthereumTransactionFee(
            regular: 5,
            priority: 7,
            gasLimit: 11,
            gasLimitContract: 13
        )
    }

    func testAbsoluteFee() {
        XCTAssertEqual(
            sut.absoluteFee(with: .regular, isContract: false),
            CryptoValue.create(minor: "55000000000", currency: .coin(.ethereum))
        )
        XCTAssertEqual(
            sut.absoluteFee(with: .regular, isContract: true),
            CryptoValue.create(minor: "65000000000", currency: .coin(.ethereum))
        )
        XCTAssertEqual(
            sut.absoluteFee(with: .priority, isContract: false),
            CryptoValue.create(minor: "77000000000", currency: .coin(.ethereum))
        )
        XCTAssertEqual(
            sut.absoluteFee(with: .priority, isContract: true),
            CryptoValue.create(minor: "91000000000", currency: .coin(.ethereum))
        )
    }
}
