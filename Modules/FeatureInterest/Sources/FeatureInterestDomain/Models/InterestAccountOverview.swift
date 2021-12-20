// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import ToolKit

public struct InterestAccountOverview: Equatable {

    public var currency: CurrencyType {
        interestAccountRate
            .cryptoCurrency
            .currencyType
    }

    public var balance: MoneyValue {
        let zero: MoneyValue = .zero(currency: currency)
        return balanceDetails?.moneyBalance ?? zero
    }

    public var totalEarned: MoneyValue {
        let zero: MoneyValue = .zero(currency: currency)
        return balanceDetails?.moneyTotalInterest ?? zero
    }

    public var accrued: MoneyValue {
        let zero: MoneyValue = .zero(currency: currency)
        return balanceDetails?.moneyPendingInterest ?? zero
    }

    public var ineligibilityReason: InterestAccountIneligibilityReason {
        interestAccountEligibility
            .ineligibilityReason
    }

    public var lockupDurationDescription: String {
        interestAccountLimits.lockupDescription
    }

    public var nextPaymentDate: String {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day = 1
        let month = components.month ?? 0
        components.month = month + 1
        components.calendar = .current
        let next = components.date ?? Date()
        return dateFormatter.string(from: next)
    }

    public let interestAccountEligibility: InterestAccountEligibility
    public let interestAccountRate: InterestAccountRate
    public let interestAccountLimits: InterestAccountLimits
    public let balanceDetails: InterestAccountBalanceDetails?

    // MARK: - Private Properties

    private let calendar: Calendar
    private let dateFormatter: DateFormatter

    // MARK: - Init

    public init(
        calendar: Calendar = .current,
        dateFormatter: DateFormatter = .long,
        interestAccountEligibility: InterestAccountEligibility,
        interestAccountRate: InterestAccountRate,
        interestAccountLimits: InterestAccountLimits,
        balanceDetails: InterestAccountBalanceDetails? = nil
    ) {
        self.calendar = calendar
        self.dateFormatter = dateFormatter
        self.interestAccountLimits = interestAccountLimits
        self.interestAccountEligibility = interestAccountEligibility
        self.interestAccountRate = interestAccountRate
        self.balanceDetails = balanceDetails
    }
}

extension InterestAccountOverview: Identifiable {
    public var id: String {
        "\(interestAccountEligibility.currencyType.code)"
    }
}

extension InterestAccountOverview {
    public static func == (
        lhs: InterestAccountOverview,
        rhs: InterestAccountOverview
    ) -> Bool {
        lhs.interestAccountEligibility == rhs.interestAccountEligibility &&
            lhs.balanceDetails == rhs.balanceDetails &&
            lhs.interestAccountLimits == rhs.interestAccountLimits &&
            lhs.interestAccountRate == rhs.interestAccountRate
    }
}
