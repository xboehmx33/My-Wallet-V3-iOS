// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
@testable import MoneyKitMock
import XCTest

class CryptoCurrencyTests: XCTestCase {

    private var cryptoCurrencyDesiredOrder: [CryptoCurrency] {
        [
            .coin(.bitcoin),
            .coin(.ethereum),
            .coin(.bitcoinCash),
            .coin(.stellar),
            .coin(.mockCoin(name: "Custodial 1", sortIndex: 5)),
            .coin(.mockCoin(name: "Custodial 2", sortIndex: 11)),
            .coin(.mockCoin(name: "Custodial 3", sortIndex: 12)),
            .coin(.mockCoin(name: "Custodial 4", sortIndex: 13)),
            .erc20(.mockERC20(name: "ERC20 1", sortIndex: 0)),
            .erc20(.mockERC20(name: "ERC20 2", sortIndex: 1)),
            .erc20(.mockERC20(name: "ERC20 3", sortIndex: 2)),
            .erc20(.mockERC20(name: "ERC20 4", sortIndex: 3)),
            .erc20(.mockERC20(name: "ERC20 5", sortIndex: 4))
        ]
    }

    func testSortedCryptoCurrencyArrayIsInCorrectOrder() {
        XCTAssertTrue(
            cryptoCurrencyDesiredOrder.shuffled().sorted() == cryptoCurrencyDesiredOrder,
            "sut.allEnabledCryptoCurrencies.sorted() is not as expected."
        )
    }

    func testUniquenessERC20AssetModel() {
        let currencies: [AssetModel] = [
            .mockERC20(name: "AAA", sortIndex: 0),
            .mockERC20(name: "AAA", sortIndex: 1),
            .mockERC20(name: "BBB", sortIndex: 2)
        ]
        let unique = currencies.unique
        XCTAssertEqual(unique.count, 2)
        let set = Set(currencies)
        XCTAssertEqual(set.count, 2)
    }

    func testUniquenessCoinAssetModel() {
        let currencies: [AssetModel] = [
            .mockCoin(name: "AAA", sortIndex: 0),
            .mockCoin(name: "AAA", sortIndex: 1),
            .mockCoin(name: "BBB", sortIndex: 2)
        ]
        let unique = currencies.unique
        XCTAssertEqual(unique.count, 2)
        let set = Set(currencies)
        XCTAssertEqual(set.count, 2)
    }

    func testUniquenessCryptoCurrency() {
        let currencies: [CryptoCurrency] = [
            .erc20(.mockERC20(name: "AAA", sortIndex: 0)),
            .erc20(.mockERC20(name: "AAA", sortIndex: 1)),
            .erc20(.mockERC20(name: "BBB", sortIndex: 2)),
            .coin(.mockCoin(name: "AAA", sortIndex: 0)),
            .coin(.mockCoin(name: "AAA", sortIndex: 1)),
            .coin(.mockCoin(name: "BBB", sortIndex: 2))
        ]
        let unique = currencies.unique
        XCTAssertEqual(unique.count, 4)
        let set = Set(currencies)
        XCTAssertEqual(set.count, 4)
    }
}
