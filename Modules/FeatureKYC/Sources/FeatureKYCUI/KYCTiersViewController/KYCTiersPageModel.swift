// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Localization
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

public struct KYCTiersPageModel {
    let header: KYCTiersHeaderViewModel
    let cells: [KYCTierCellModel]
}

extension KYCTiersPageModel {

    var disclaimer: String? {
        guard let tierTwo = cells.first(where: { $0.tier == .tier2 }) else { return nil }
        guard tierTwo.status != .rejected else { return nil }
        return LocalizationConstants.KYC.completingTierTwoAutoEligible
    }

    func trackPresentation(analyticsRecorder: AnalyticsEventRecorderAPI = resolve()) {
        let metadata = cells.map { ($0.tier, $0.status) }
        guard let tier1 = metadata.first(where: { $0.0 == .tier1 }) else { return }
        guard let tier2 = metadata.first(where: { $0.0 == .tier2 }) else { return }
        let tierOneStatus = tier1.1
        let tierTwoStatus = tier2.1
        switch (tierOneStatus, tierTwoStatus) {
        case (.none, .none):
            analyticsRecorder.record(event: AnalyticsEvents.KYC.kycTiersLocked)
        case (.approved, .none):
            analyticsRecorder.record(event: AnalyticsEvents.KYC.kycTier1Complete)
        case (_, .inReview),
             (_, .approved):
            analyticsRecorder.record(event: AnalyticsEvents.KYC.kycTier2Complete)
        default:
            break
        }
    }

    public static func make(tiers: KYC.UserTiers, maxTradableToday: FiatValue, suppressCTA: Bool) -> KYCTiersPageModel {
        let header = KYCTiersHeaderViewModel.make(
            with: tiers,
            availableFunds: maxTradableToday.toDisplayString(includeSymbol: true, format: .shortened, locale: .current),
            suppressDismissCTA: suppressCTA
        )
        let models = tiers.tiers
            .filter { $0.tier != .tier0 }
            .map { KYCTierCellModel.model(from: $0) }
            .compactMap { $0 }
        return KYCTiersPageModel(header: header, cells: models)
    }
}
