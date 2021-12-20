// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

extension KYC {
    /// Enumerates the different tiers for KYC. A higher tier requires
    /// users to provide us with more information about them which
    /// qualifies them for higher limits of trading.
    ///
    /// - tier1: the 1st tier requiring the user to only provide basic
    ///          user information such as name and address.
    /// - tier2: the 2nd tier requiring the user to provide additional
    ///          identity information such as a drivers licence, passport,
    ///          etc.
    /// - SeeAlso: https://docs.google.com/spreadsheets/d/1BEdFJtbXpjcwolOljFRVBDjoe6GAoGvUkFCOzlUM_dM/edit#gid=1035097792
    public enum Tier: Int, CaseIterable, Codable, Comparable {
        /// no kyc info provided
        case tier0 = 0
        /// Silver: We know name and address. Can't buy or sell, unless SDD-verified.
        case tier1 = 1
        /// Gold: We verified the user's identity. They can do everything.
        case tier2 = 2

        // It's best to use comparison to compare tiers instead of using `==` directly
        // since additional values are likely to be added in future
        public static func < (lhs: Tier, rhs: Tier) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

extension KYC.Tier {

    public var isZero: Bool {
        self == .tier0
    }

    public var isSiver: Bool {
        self == .tier1
    }

    public var isGold: Bool {
        self == .tier2
    }
}
