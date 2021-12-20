// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import FeatureInterestDomain
import MoneyKit
import PlatformKit

public struct InterestAccountLimitsResponse: Decodable {

    public static let empty = InterestAccountLimitsResponse()

    // MARK: - Properties

    private let limits: [String: InterestLimits]

    // MARK: - Init

    private init() {
        limits = [:]
    }

    private enum CodingKeys: String, CodingKey {
        case limits
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        limits = try values.decode([String: InterestLimits].self, forKey: .limits)
    }

    // MARK: - Subscript

    subscript(currency: CryptoCurrency) -> InterestLimits? {
        limits[currency.code]
    }
}
