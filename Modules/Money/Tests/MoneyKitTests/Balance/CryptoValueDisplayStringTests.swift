// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import XCTest

class CryptoValueDisplayStringTests: XCTestCase {
    func testBTC() {
        let minor = CryptoValue.create(minor: BigInt("1"), currency: .coin(.bitcoin))
        let cases: [(locale: Locale, string: String)] = [
            (.US, "0.00000001 BTC"),
            (.Canada, "0.00000001 BTC"),
            (.France, "0,00000001 BTC"),
            (.Japan, "0.00000001 BTC"),
            (.GreatBritain, "0.00000001 BTC"),
            (.Lithuania, "0,00000001 BTC")
        ]
        for this in cases {
            let result = minor.toDisplayString(includeSymbol: true, locale: this.locale)
            XCTAssertEqual(
                result,
                this.string,
                "\(this.locale), \(this.string): got \(result) instead"
            )
        }
    }
}
