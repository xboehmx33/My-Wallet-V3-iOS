// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import XCTest

final class MoneyValuePairExchangeRateTests: XCTestCase {

    func test_inverts_pair_fiat_to_crypto() {
        // GIVEN: The exchange rate USD-BTC
        let originalPair = MoneyValuePair(
            base: .one(currency: .USD),
            exchangeRate: MoneyValue(
                amount: 000003357,
                currency: .crypto(.coin(.bitcoin))
            )
        )
        XCTAssertEqual(originalPair.quote.displayString, "0.00003357 BTC")

        // WHEN: Getting the inverse quote
        let inversePair = originalPair.inverseExchangeRate

        // THEN: The inverted quote should be the equivalent value for BTC-USD (1 / the original quote)
        XCTAssertEqual(inversePair.quote.displayString, "$29,788.50")
        let expectedInversePair = MoneyValuePair(
            base: .one(currency: .crypto(.coin(.bitcoin))),
            exchangeRate: .init(amount: 2978850, currency: .fiat(.USD))
        )
        XCTAssertEqual(inversePair, expectedInversePair)
    }

    func test_inverts_pair_crypto_to_fiat() {
        // GIVEN: The exchange rate BTC-USD
        let originalPair = MoneyValuePair(
            base: .one(currency: .crypto(.coin(.bitcoin))),
            exchangeRate: MoneyValue(
                amount: 2978850,
                currency: .fiat(.USD)
            )
        )
        XCTAssertEqual(originalPair.quote.displayString, "$29,788.50")

        // WHEN: Getting the inverse quote
        let inversePair = originalPair.inverseExchangeRate

        // THEN: The inverted quote should be the equivalent value for USD-BTC (1 / the original quote)
        XCTAssertEqual(inversePair.quote.displayString, "0.00003357 BTC")
        let expectedInversePair = MoneyValuePair(
            base: .one(currency: .USD),
            exchangeRate: .init(
                amount: 000003357,
                currency: .crypto(.coin(.bitcoin))
            )
        )
        XCTAssertEqual(inversePair, expectedInversePair)
    }

    func test_inverts_with_non_one_base() {
        // GIVEN: A FX where the bsse is non-1
        let originalPair = MoneyValuePair(
            base: CryptoValue.create(major: "5", currency: .coin(.ethereum))!,
            exchangeRate: FiatValue.create(major: "800", currency: .USD)!
        )
        XCTAssertEqual(originalPair.quote.displayString, "$4,000.00")

        // WHEN: Getting the inverse quote
        let inversePair = originalPair.inverseExchangeRate

        // THEN: The inverse should return a 1 based FX anyway
        let expectedInversePair = MoneyValuePair(
            base: .one(currency: .fiat(.USD)),
            quote: .create(major: "0.00125", currency: .crypto(.coin(.ethereum)))!
        )
        XCTAssertEqual(inversePair, expectedInversePair)
    }

    func test_inverting_a_zero_based_pair_returns_zero() {
        // GIVEN: A FX where the bsse is 0
        let originalPair = MoneyValuePair(
            base: .zero(currency: .coin(.ethereum)),
            // doesn't matter what the exchange rate is: the pair is invalid
            exchangeRate: FiatValue.create(major: "800", currency: .USD)!
        )
        XCTAssertEqual(originalPair.quote.displayString, "$0.00")

        // WHEN: Getting the inverse quote
        let inversePair = originalPair.inverseExchangeRate

        // THEN: The inverse should return a 1 based FX anyway
        let expectedInversePair: MoneyValuePair = .zero(
            baseCurrency: .fiat(.USD),
            quoteCurrency: .crypto(.coin(.ethereum))
        )
        XCTAssertEqual(inversePair, expectedInversePair)
    }

    func test_inverting_a_zero_quoted_pair_returns_zero() {
        // GIVEN: A FX where the bsse is 0
        let originalPair = MoneyValuePair(
            base: .one(currency: .coin(.ethereum)),
            // doesn't matter what the exchange rate is: the pair is invalid
            exchangeRate: .zero(currency: .fiat(.USD))
        )
        XCTAssertEqual(originalPair.quote.displayString, "$0.00")

        // WHEN: Getting the inverse quote
        let inversePair = originalPair.inverseExchangeRate

        // THEN: The inverse should return a 1 based FX anyway
        let expectedInversePair: MoneyValuePair = .zero(
            baseCurrency: .fiat(.USD),
            quoteCurrency: .crypto(.coin(.ethereum))
        )
        XCTAssertEqual(inversePair, expectedInversePair)
    }
}
