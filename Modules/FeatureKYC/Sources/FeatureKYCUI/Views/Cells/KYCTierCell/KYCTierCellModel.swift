// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit

struct KYCTierCellModel {

    // Only using this to test cells
    enum ApprovalStatus {
        case none
        case infoRequired
        case inReview
        case underReview
        case approved
        case rejected
    }

    let tier: KYC.Tier
    let status: ApprovalStatus
    let fiatValue: FiatValue
}

extension KYCTierCellModel {

    var limitDescription: String {
        fiatValue.toDisplayString(includeSymbol: true, format: .shortened, locale: .current)
    }

    var requirementsVisibility: Visibility {
        guard status == .none else { return .hidden }
        return .visible
    }

    var statusVisibility: Visibility {
        switch status {
        case .none,
             .rejected:
            return .hidden
        case .inReview,
             .infoRequired,
             .underReview,
             .approved:
            return .visible
        }
    }

    var headlineContainerVisibility: Visibility {
        guard tier.headline != nil else { return .hidden }
        let hide: [ApprovalStatus] = [.rejected, .approved]
        guard hide.contains(where: { $0 == self.status }) == false else { return .hidden }
        return .visible
    }

    var durationEstimateVisibility: Visibility {
        guard status == .none else { return .hidden }
        return .visible
    }
}

extension KYCTierCellModel.ApprovalStatus {
    var description: String? {
        switch self {
        case .none:
            return nil
        case .infoRequired:
            return LocalizationConstants.KYC.swapStatusInReviewCTA
        case .inReview:
            return LocalizationConstants.KYC.swapStatusInReview
        case .underReview:
            return LocalizationConstants.KYC.swapStatusUnderReview
        case .approved:
            return LocalizationConstants.KYC.swapStatusApproved
        case .rejected:
            return nil
        }
    }

    var color: UIColor? {
        switch self {
        case .none,
             .rejected:
            return #colorLiteral(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
        case .infoRequired,
             .inReview:
            return #colorLiteral(red: 0.95, green: 0.55, blue: 0.19, alpha: 1)
        case .underReview:
            return #colorLiteral(red: 0.82, green: 0.01, blue: 0.11, alpha: 1)
        case .approved:
            return #colorLiteral(red: 0.21, green: 0.66, blue: 0.46, alpha: 1)
        }
    }

    var image: UIImage {
        switch self {
        case .none:
            return UIImage(named: "icon_chevron", in: .featureKYCUI, compatibleWith: nil)!
        case .rejected:
            return UIImage(named: "icon_lock", in: .featureKYCUI, compatibleWith: nil)!
        case .infoRequired,
             .inReview:
            return UIImage(named: "icon_clock", in: .featureKYCUI, compatibleWith: nil)!
        case .underReview:
            return UIImage(named: "icon_alert", in: .featureKYCUI, compatibleWith: nil)!
        case .approved:
            return UIImage(named: "icon_check", in: .featureKYCUI, compatibleWith: nil)!
        }
    }
}

extension KYCTierCellModel {

    static func model(
        from userTier: KYC.UserTier
    ) -> KYCTierCellModel? {
        let value = approvalStatusFromTierState(userTier.state)
        // NOTE: hardcoded for now (IOS-5581), but it will be fixed in upcoming limits revamp work.
        let fiatValue: FiatValue
        if userTier.tier == .tier1 {
            fiatValue = FiatValue(amount: 200000, currency: .USD)
        } else if userTier.tier == .tier2 {
            fiatValue = FiatValue(amount: 50000000, currency: .USD)
        } else {
            fiatValue = .zero(currency: .USD)
        }
        return KYCTierCellModel(tier: userTier.tier, status: value, fiatValue: fiatValue)
    }

    fileprivate static func approvalStatusFromTierState(_ tierState: KYC.Tier.State) -> ApprovalStatus {
        switch tierState {
        case .none:
            return .none
        case .verified:
            return .approved
        case .pending:
            return .inReview
        case .rejected:
            return .rejected
        }
    }
}
