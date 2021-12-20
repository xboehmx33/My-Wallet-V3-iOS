// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public struct SuggestedAmounts {

    public subscript(currency: FiatCurrency) -> [FiatValue] {
        amountsPerCurrency[currency] ?? []
    }

    private let amountsPerCurrency: [FiatCurrency: [FiatValue]]

    init(response: SuggestedAmountsResponse) {
        amountsPerCurrency = response.amounts
            .reduce(into: [FiatCurrency: [FiatValue]]()) { result, element in
                guard let currency = FiatCurrency(code: element.key) else { return }
                result[currency] = element.value.map { FiatValue.create(minor: $0, currency: currency)! }
            }
    }
}
