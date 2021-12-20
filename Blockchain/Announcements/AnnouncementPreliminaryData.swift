// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureAuthenticationDomain
import MoneyKit
import PlatformKit
import WalletPayloadKit

/// Contains any needed remotely fetched data before displaying announcements.
struct AnnouncementPreliminaryData {

    // MARK: Types

    struct AssetRename {
        let asset: CryptoCurrency
        let oldTicker: String
        let balance: MoneyValue
    }

    struct SimpleBuy {
        let hasLinkedBanks: Bool
        let isAvailable: Bool
        let isEligible: Bool
        let pendingOrderDetails: [OrderDetails]
    }

    // MARK: Properties

    /// CeloEUR CryptoCurrency if it exists.
    let celoEUR: CryptoCurrency?

    /// Announcement New Asset
    let newAsset: CryptoCurrency?

    /// Announcement Asset Rename
    let assetRename: AssetRename?

    /// The nabu user
    let user: NabuUser

    /// User tiers information
    let tiers: KYC.UserTiers

    /// User Simplified Due Diligence Eligibility
    let isSDDEligible: Bool

    let country: CountryData?

    /// The authentication type (2FA / standard)
    let authenticatorType: WalletAuthenticatorType

    var hasLinkedExchangeAccount: Bool {
        user.hasLinkedExchangeAccount
    }

    var isKycSupported: Bool {
        country?.isKycSupported ?? false
    }

    var hasTwoFA: Bool {
        authenticatorType != .standard
    }

    let simpleBuy: SimpleBuy

    var hasIncompleteBuyFlow: Bool {
        simpleBuyEventCache[.hasShownBuyScreen] && simpleBuy.isAvailable
    }

    /// Whether the user has a wallet balance in any account.
    let hasAnyWalletBalance: Bool

    private let simpleBuyEventCache: EventCache

    init(
        user: NabuUser,
        tiers: KYC.UserTiers,
        isSDDEligible: Bool,
        countries: [CountryData],
        simpleBuyEventCache: EventCache = resolve(),
        authenticatorType: WalletAuthenticatorType,
        hasAnyWalletBalance: Bool,
        newAsset: CryptoCurrency?,
        assetRename: AssetRename?,
        simpleBuy: SimpleBuy,
        celoEUR: CryptoCurrency?
    ) {
        self.user = user
        self.tiers = tiers
        self.isSDDEligible = isSDDEligible
        self.simpleBuyEventCache = simpleBuyEventCache
        self.authenticatorType = authenticatorType
        self.hasAnyWalletBalance = hasAnyWalletBalance
        self.newAsset = newAsset
        self.assetRename = assetRename
        self.simpleBuy = simpleBuy
        self.celoEUR = celoEUR
        country = countries.first { $0.code == user.address?.countryCode }
    }
}
