// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public struct KYCLimitsOverview: Equatable {

    public let tiers: KYC.UserTiers
    public let features: [LimitedTradeFeature]

    public init(tiers: KYC.UserTiers, features: [LimitedTradeFeature]) {
        self.tiers = tiers
        self.features = features
    }
}
