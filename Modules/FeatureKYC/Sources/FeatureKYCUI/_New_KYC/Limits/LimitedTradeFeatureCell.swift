// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import ComposableArchitecture
import MoneyKit
import PlatformKit
import SwiftUI

struct LimitedTradeFeatureCell: View {

    let feature: LimitedTradeFeature

    var body: some View {
        HStack(spacing: Spacing.padding2) {
            feature.icon
                .frame(width: 24, height: 24)
                .accentColor(.semantic.title)
            VStack(alignment: .leading, spacing: Spacing.textSpacing) {
                Text(feature.title)
                    .typography(.body2)
                if let message = feature.message {
                    Text(message)
                        .typography(.caption1)
                }
            }
            Spacer()
            Text(feature.valueDisplayString)
                .typography(.body2)
                .accentColor(Color.semantic.body)
                .foregroundColor(Color.semantic.body)
        }
        .padding(Spacing.padding3)
        .frame(maxWidth: .infinity, minHeight: 80)
    }
}

struct LimitedTradeFeatureCell_Previews: PreviewProvider {

    static let exampleFeatures: [LimitedTradeFeature] = [
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

    static var previews: some View {
        VStack(alignment: .leading, spacing: Spacing.baseline) {
            ForEach(exampleFeatures) { feature in
                LimitedTradeFeatureCell(
                    feature: feature
                )
            }
        }
    }
}
