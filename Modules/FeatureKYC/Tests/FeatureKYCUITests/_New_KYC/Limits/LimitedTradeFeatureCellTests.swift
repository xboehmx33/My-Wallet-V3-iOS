// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
@testable import FeatureKYCUI
import MoneyKit
import PlatformKit
import SnapshotTesting
import XCTest

final class LimitedTradeFeatureCellTests: XCTestCase {

    let exampleFeatures: [LimitedTradeFeature] = [
        LimitedTradeFeature(
            id: .send,
            enabled: true,
            limit: .init(
                value: MoneyValue(amount: 200000, currency: .fiat(.USD)),
                period: .year
            )
        ),
        LimitedTradeFeature(
            id: .receive,
            enabled: true,
            limit: .init(
                value: MoneyValue(amount: 200000, currency: .fiat(.USD)),
                period: .year
            )
        ),
        LimitedTradeFeature(
            id: .swap,
            enabled: true,
            limit: .init(
                value: MoneyValue(amount: 200000, currency: .fiat(.USD)),
                period: .year
            )
        ),
        LimitedTradeFeature(
            id: .sell,
            enabled: true,
            limit: nil
        ),
        LimitedTradeFeature(
            id: .buyWithCard,
            enabled: true,
            limit: .init(
                value: MoneyValue(amount: 200000, currency: .fiat(.USD)),
                period: .year
            )
        ),
        LimitedTradeFeature(
            id: .buyWithBankAccount,
            enabled: false,
            limit: nil
        ),
        LimitedTradeFeature(
            id: .withdraw,
            enabled: false,
            limit: nil
        ),
        LimitedTradeFeature(
            id: .rewards,
            enabled: true,
            limit: .init(value: nil, period: .year)
        )
    ]

    func test_basic_info_for_all_features() throws {
        for feature in exampleFeatures {
            let view = LimitedTradeFeatureCell(feature: feature)
                .frame(width: 320)
                .fixedSize()

            assertSnapshots(
                matching: view,
                as: [
                    .image(traits: UITraitCollection(userInterfaceStyle: .light)),
                    .image(traits: UITraitCollection(userInterfaceStyle: .dark))
                ]
            )
        }
    }
}
