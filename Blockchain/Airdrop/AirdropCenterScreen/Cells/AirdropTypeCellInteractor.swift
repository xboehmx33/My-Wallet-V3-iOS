// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

struct AirdropTypeCellInteractor {

    // MARK: - Properties

    let campaignIdentifier: String
    let fiatValue: FiatValue?
    let cryptoCurrency: TriageCryptoCurrency
    let dropDate: Date?
    let isAvailable: Bool

    // MARK: - Injected

    private let campaign: AirdropCampaigns.Campaign

    // MARK: - Setup

    init(campaign: AirdropCampaigns.Campaign) {
        self.campaign = campaign
        campaignIdentifier = campaign.name
        isAvailable = campaign.state == .started
        dropDate = campaign.dropDate
        cryptoCurrency = campaign.cryptoCurrency
        fiatValue = campaign.latestTransaction?.fiat
    }
}

// MARK: - Equatable

extension AirdropTypeCellInteractor: Equatable {
    static func == (lhs: AirdropTypeCellInteractor, rhs: AirdropTypeCellInteractor) -> Bool {
        lhs.campaignIdentifier == rhs.campaignIdentifier
    }
}
