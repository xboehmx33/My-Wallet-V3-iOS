// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

/// Enumerates app features that can be dynamically configured (e.g. enabled/disabled)
public enum AppFeature: Int, CaseIterable {

    // MARK: - Local features

    case biometry

    // MARK: - Firebase features

    /// The announcements
    case announcements

    /// The ticker for the new asset announcement.
    case newAssetAnnouncement

    /// The ticker for the asset rename announcement.
    case assetRenameAnnouncement

    /// Sift Science SDK is enabled
    case siftScienceEnabled

    // MARK: Wallet Connect

    case walletConnectEnabled

    // MARK: Onboarding (After Login)

    /// Shows Email Verification insted of Simple Buy at Login
    case showOnboardingAfterSignUp

    /// Shows Email Verification in Onboarding, otherwise just show the buy flow
    case showEmailVerificationInOnboarding

    /// Shows Email Verification, if needed, when a user tries to make a purchase
    case showEmailVerificationInBuyFlow

    // MARK: - SSO

    case unifiedSignIn

    case pollingForEmailLogin

    // MARK: - SDD

    /// Enables SDD checks. If `false`, all checks immediately fail
    case sddEnabled

    /// Enable ACH withdraw and deposit
    case withdrawAndDepositACH

    /// Enable interest withdraw and deposit
    case interestWithdrawAndDeposit

    /// Enable Zen-Desk Messaging for Gold Verified Users
    case customerSupportChat

    /// Enable Open Banking
    case openBanking

    /// Enable New Card Acquirers (Stripe & Checkout)
    case newCardAcquirers

    /// Enables the new Limits UI in Transaction Flow
    case newLimitsUIEnabled

    /// Enables the new pricing model
    case newQuoteForSimpleBuy

    // MARK: - Account Picker

    /// New SwiftUI account picker from `FeatureAccountPicker`
    case swiftUIAccountPicker

    // MARK: - Onboarding

    /// New tour view from `FeatureTour`
    case newOnboardingTour

    // MARK: - Redesign

    case redesign

    case fab
}

extension AppFeature {
    /// The remote key which determines if this feature is enabled or not
    public var remoteEnabledKey: String? {
        switch self {
        case .interestWithdrawAndDeposit:
            return "ios_interest_deposit_withdraw"
        case .announcements:
            return "announcements"
        case .newAssetAnnouncement:
            return "new_asset_announcement_ticker"
        case .assetRenameAnnouncement:
            return "rename_asset_announcement_ticker"
        case .siftScienceEnabled:
            return "sift_science_enabled"
        case .withdrawAndDepositACH:
            return "ach_withdraw_deposit_enabled"
        case .biometry:
            return nil
        case .showOnboardingAfterSignUp:
            return "show_onboarding_after_sign_up_ios"
        case .showEmailVerificationInOnboarding:
            return "show_email_verification_in_onboarding_ios"
        case .showEmailVerificationInBuyFlow:
            return "show_email_verification_in_buy_flow_ios"
        case .unifiedSignIn:
            return "sso_unified_sign_in_enabled_ios"
        case .pollingForEmailLogin:
            return "ios_ff_sso_polling"
        case .sddEnabled:
            return "sdd_enabled_ios"
        case .customerSupportChat:
            return "customer_support_chat_ios"
        case .openBanking:
            return "ios_open_banking"
        case .newCardAcquirers:
            return "ios_ff_new_card_acquirers"
        case .newLimitsUIEnabled:
            return "ios_use_new_limits_ui"
        case .newQuoteForSimpleBuy:
            return "ios_ff_new_pricing"
        case .swiftUIAccountPicker:
            return "ios_swiftui_account_picker"
        case .walletConnectEnabled:
            return "ios_ff_wallet_connect"
        case .redesign:
            return "ios_ff_redesign"
        case .fab:
            return "ios_fab_data"
        case .newOnboardingTour:
            return "ios_ff_new_onboarding_tour"
        }
    }

    /// Enables the feature for alpha release by overriding remote config settings.
    var isAlphaReady: Bool {
        switch self {
        case .newAssetAnnouncement:
            return false
        case .assetRenameAnnouncement:
            return false
        case .interestWithdrawAndDeposit:
            return false
        case .announcements:
            return false
        case .siftScienceEnabled:
            return false
        case .withdrawAndDepositACH:
            return false
        case .biometry:
            return false
        case .showOnboardingAfterSignUp:
            return false
        case .showEmailVerificationInOnboarding:
            return false
        case .showEmailVerificationInBuyFlow:
            return false
        case .unifiedSignIn:
            return false
        case .pollingForEmailLogin:
            return true
        case .sddEnabled:
            return false
        case .customerSupportChat:
            return false
        case .newCardAcquirers:
            return true
        case .openBanking:
            return true
        case .newLimitsUIEnabled:
            return true
        case .newQuoteForSimpleBuy:
            return true
        case .swiftUIAccountPicker:
            return true
        case .walletConnectEnabled:
            return true
        case .redesign:
            return true
        case .fab:
            return true
        case .newOnboardingTour:
            return true
        }
    }
}

public struct AssetRenameAnnouncementFeature: Decodable {
    public let networkTicker: String
    public let oldTicker: String
}
