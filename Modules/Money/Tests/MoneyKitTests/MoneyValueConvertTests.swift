// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import MoneyKit
import XCTest

final class MoneyValueConvertTests: XCTestCase {

    var mockCoin6Precision: AssetModel {
        AssetModel(
            code: "MOCK",
            displayCode: "MOCK",
            kind: .coin(minimumOnChainConfirmations: 0),
            name: "Mock Coin",
            precision: 6,
            products: [],
            logoPngUrl: nil,
            spotColor: nil,
            sortIndex: 0
        )
    }

    func testConvertingALGOIntoBTCUsingBTCExchangeRate() {
        let exchangeRate = CryptoValue(
            amount: 400,
            currency: .coin(.bitcoin)
        ).moneyValue
        let value = CryptoValue(
            amount: 10000,
            currency: .coin(mockCoin6Precision)
        ).moneyValue
        let expected = CryptoValue(
            amount: 4,
            currency: .coin(.bitcoin)
        ).moneyValue
        let result = value.convert(using: exchangeRate)
        XCTAssertEqual(result, expected)
    }

    func testConvertingBTCIntoALGOUsingBTCExchangeRate() {
        let exchangeRate = CryptoValue(
            amount: 400,
            currency: .coin(.bitcoin)
        ).moneyValue
        let value = CryptoValue(
            amount: 4,
            currency: .coin(.bitcoin)
        ).moneyValue
        let expected = CryptoValue(
            amount: 10000,
            currency: .coin(mockCoin6Precision)
        ).moneyValue
        let result = value.convert(
            usingInverse: exchangeRate,
            currencyType: .crypto(.coin(mockCoin6Precision))
        )
        XCTAssertEqual(result, expected)
    }
}
