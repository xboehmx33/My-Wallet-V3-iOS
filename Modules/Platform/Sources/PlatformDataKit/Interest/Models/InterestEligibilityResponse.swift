// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

struct InterestEligibilityResponse: Decodable {

    // MARK: - Properties

    let interestEligibilities: [String: InterestEligibility]

    // MARK: - Init

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            interestEligibilities = try container.decode([String: InterestEligibility].self)
        } catch {
            interestEligibilities = [:]
        }
    }

    // MARK: - Subscript

    subscript(currencyType: CurrencyType) -> InterestEligibility? {
        interestEligibilities[currencyType.code]
    }
}
