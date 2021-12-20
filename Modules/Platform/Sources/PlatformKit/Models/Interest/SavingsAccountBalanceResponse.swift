// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public struct SavingsAccountBalanceResponse: Decodable {

    public static let empty = SavingsAccountBalanceResponse()

    // MARK: - Properties

    public let balances: [String: SavingsAccountBalanceDetails]

    // MARK: - Init

    private init() {
        balances = [:]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        balances = try container.decode([String: SavingsAccountBalanceDetails].self)
    }

    // MARK: - Subscript

    public subscript(currency: CryptoCurrency) -> SavingsAccountBalanceDetails? {
        balances[currency.code]
    }
}
