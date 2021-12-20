// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import PlatformKit
import RxSwift

public final class KYCPager: KYCPagerAPI {

    private let nabuUserService: NabuUserServiceAPI
    public private(set) var tier: KYC.Tier
    public private(set) var tiersResponse: KYC.UserTiers

    public init(
        nabuUserService: NabuUserServiceAPI = resolve(),
        tier: KYC.Tier,
        tiersResponse: KYC.UserTiers
    ) {
        self.nabuUserService = nabuUserService
        self.tier = tier
        self.tiersResponse = tiersResponse
    }

    public func nextPage(from page: KYCPageType, payload: KYCPagePayload?) -> Maybe<KYCPageType> {
        // Get country from payload if present
        var kycCountry: CountryData?
        if let payload = payload {
            switch payload {
            case .countrySelected(let country):
                kycCountry = country
            case .sddVerification(let isVerified):
                return isVerified ? .empty() : .just(.verifyIdentity)
            case .stateSelected:
                // no-op: handled in coordinator
                break
            case .phoneNumberUpdated,
                 .emailPendingVerification,
                 .accountStatus:
                // Not handled here
                break
            }
        }
        return nabuUserService.user.asSingle()
            .flatMapMaybe { [weak self] user -> Maybe<KYCPageType> in
                guard let strongSelf = self else {
                    return Maybe.empty()
                }
                guard let nextPage = page.nextPage(
                    forTier: strongSelf.tier,
                    user: user,
                    country: kycCountry,
                    tiersResponse: strongSelf.tiersResponse
                ) else {
                    return strongSelf.nextPageFromNextTierMaybe()
                }
                return Maybe.just(nextPage)
            }
    }

    private func nextPageFromNextTierMaybe() -> Maybe<KYCPageType> {
        nabuUserService.fetchUser().asSingle().flatMapMaybe { [weak self] user -> Maybe<KYCPageType> in
            guard let strongSelf = self else {
                return Maybe.empty()
            }
            guard let tiers = user.tiers else {
                return Maybe.empty()
            }

            let nextTier = tiers.next

            // If the next tier is the same as the tier property in KYCPager, this means that the
            // user has already completely the flow for the tier property.
            guard nextTier != strongSelf.tier else {
                return Maybe.empty()
            }

            guard nextTier.rawValue > tiers.selected.rawValue else {
                return Maybe.empty()
            }

            guard let moreInfoPage = KYCPageType.moreInfoPage(forTier: nextTier) else {
                return Maybe.empty()
            }

            // If all guard checks pass, this means that we have determined that the user should be
            // forced to KYC on the next tier
            strongSelf.tier = nextTier

            return Maybe.just(moreInfoPage)
        }
    }
}

// MARK: KYCPageType Extensions

extension KYCPageType {

    public static func startingPage(
        forUser user: NabuUser,
        tiersResponse: KYC.UserTiers,
        isSDDEligible: Bool,
        isSDDVerified: Bool
    ) -> KYCPageType {
        if !user.email.verified {
            return .enterEmail
        }

        if user.address == nil {
            return .country
        }

        if user.address?.postalCode == nil {
            return .profile
        }

        if let mobile = user.mobile, mobile.verified {
            if tiersResponse.canCompleteTier2 {
                if isSDDVerified {
                    // if they are SDD verified we should move on to buy but since this method doesn't allow returning nil, go to the SDD check first
                    // from there you should get redirected to buy
                    return .sddVerificationCheck // this
                } else if isSDDEligible {
                    // if they are SDD eligible, perform the SDD check and decide
                    return .sddVerificationCheck
                }

                // If the user can complete tier2 than they
                // either need to resubmit their documents
                // or submit their documents for the first time.
                return user.needsDocumentResubmission == nil ? .verifyIdentity : .resubmitIdentity
            } else {
                return .accountStatus
            }
        }

        return .enterPhone
    }

    public static func moreInfoPage(forTier tier: KYC.Tier) -> KYCPageType? {
        switch tier {
        case .tier2:
            return .tier1ForcedTier2
        default:
            return nil
        }
    }

    public func nextPage(
        forTier tier: KYC.Tier,
        user: NabuUser?,
        country: CountryData?,
        tiersResponse: KYC.UserTiers
    ) -> KYCPageType? {
        switch tier {
        case .tier0,
             .tier1:
            return nextPageTier1(user: user, country: country, tiersResponse: tiersResponse)
        case .tier2:
            return nextPageTier2(user: user, country: country, tiersResponse: tiersResponse)
        }
    }

    private func nextPageTier1(user: NabuUser?, country: CountryData?, tiersResponse: KYC.UserTiers) -> KYCPageType? {
        switch self {
        case .welcome:
            if let user = user {
                // We can pass true here, as non-eligible users would get send to the Tier 2 upgrade path anyway
                return KYCPageType.startingPage(forUser: user, tiersResponse: tiersResponse, isSDDEligible: true, isSDDVerified: false)
            }
            return .enterEmail
        case .enterEmail:
            return .confirmEmail
        case .confirmEmail:
            return .country
        case .country:
            if let country = country, country.states.count != 0 {
                return .states
            }
            if let user = user, user.personalDetails.isComplete == true {
                return .address
            }
            return .profile
        case .states:
            return .profile
        case .profile:
            return .address
        case .address:
            return .sddVerificationCheck
        case .sddVerificationCheck:
            // END
            return nil
        case .tier1ForcedTier2,
             .enterPhone,
             .confirmPhone,
             .verifyIdentity,
             .resubmitIdentity,
             .applicationComplete,
             .accountStatus:
            // All other pages don't have a next page for tier 1
            return nil
        }
    }

    private func nextPageTier2(user: NabuUser?, country: CountryData?, tiersResponse: KYC.UserTiers) -> KYCPageType? {
        switch self {
        case .address:
            return .sddVerificationCheck
        case .sddVerificationCheck,
             .tier1ForcedTier2:
            // Skip the enter phone step if the user already has verified their phone number
            if let user = user, let mobile = user.mobile, mobile.verified {
                if tiersResponse.canCompleteTier2 {
                    return user.needsDocumentResubmission == nil ? .verifyIdentity : .resubmitIdentity
                }
                // The user can't complete tier2, so they should see their account status.
                return .accountStatus
            }
            return .enterPhone
        case .enterPhone:
            return .confirmPhone
        case .confirmPhone:
            return user?.needsDocumentResubmission == nil ? .verifyIdentity : .resubmitIdentity
        case .verifyIdentity,
             .resubmitIdentity:
            return .accountStatus
        case .applicationComplete:
            // Not used
            return nil
        case .accountStatus:
            return nil
        case .welcome,
             .enterEmail,
             .confirmEmail,
             .country,
             .states,
             .profile:
            return nextPageTier1(user: user, country: country, tiersResponse: tiersResponse)
        }
    }
}
