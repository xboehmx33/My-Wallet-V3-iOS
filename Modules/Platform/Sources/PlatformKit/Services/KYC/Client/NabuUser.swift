// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit

public struct NabuUser: Decodable, Equatable {

    // MARK: - Types

    public enum UserState: String, Codable {
        case none = "NONE"
        case created = "CREATED"
        case active = "ACTIVE"
        case blocked = "BLOCKED"
    }

    /// Products used by the user
    public struct ProductsUsed: Decodable, Equatable {

        private enum CodingKeys: String, CodingKey {
            case exchange
        }

        let exchange: Bool

        public init(exchange: Bool) {
            self.exchange = exchange
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            exchange = try values.decodeIfPresent(Bool.self, forKey: .exchange) ?? false
        }
    }

    // MARK: - Properties

    public let identifier: String
    public let personalDetails: PersonalDetails
    public let address: UserAddress?
    @available(*, deprecated, message: "Never read this! This may be an old email address! Use Wallet API instead!")
    public let email: Email
    public let mobile: Mobile?
    public let status: KYC.AccountStatus
    public let state: UserState
    public let tiers: KYC.UserState?
    public let tags: Tags?
    public let needsDocumentResubmission: DocumentResubmission?
    public let userName: String?
    public let depositAddresses: [DepositAddress]
    private let productsUsed: ProductsUsed?
    private let settings: NabuUserSettings?

    /// ISO-8601 Timestamp w/millis, eg 2018-08-15T17:00:45.129Z
    public let kycCreationDate: String?

    /// ISO-8601 Timestamp w/millis, eg 2018-08-15T17:00:45.129Z
    public let kycUpdateDate: String?

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case address
        case status = "kycState"
        case state
        case tags
        case tiers
        case needsDocumentResubmission = "resubmission"
        case userName
        case settings
        case productsUsed
        case kycCreationDate = "insertedAt"
        case kycUpdateDate = "updatedAt"
        case depositAddresses = "walletAddresses"
    }

    // MARK: - Init

    public init(
        identifier: String,
        personalDetails: PersonalDetails,
        address: UserAddress?,
        email: Email,
        mobile: Mobile?,
        status: KYC.AccountStatus,
        state: UserState,
        tags: Tags?,
        tiers: KYC.UserState?,
        needsDocumentResubmission: DocumentResubmission?,
        userName: String? = nil,
        depositAddresses: [DepositAddress] = [],
        productsUsed: ProductsUsed,
        settings: NabuUserSettings,
        kycCreationDate: String? = nil,
        kycUpdateDate: String? = nil
    ) {
        self.identifier = identifier
        self.personalDetails = personalDetails
        self.address = address
        self.email = email
        self.mobile = mobile
        self.status = status
        self.state = state
        self.tags = tags
        self.tiers = tiers
        self.needsDocumentResubmission = needsDocumentResubmission
        self.userName = userName
        self.depositAddresses = depositAddresses
        self.productsUsed = productsUsed
        self.settings = settings
        self.kycCreationDate = kycCreationDate
        self.kycUpdateDate = kycUpdateDate
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try values.decode(String.self, forKey: .identifier)
        address = try values.decodeIfPresent(UserAddress.self, forKey: .address)
        tiers = try values.decodeIfPresent(KYC.UserState.self, forKey: .tiers)
        userName = try values.decodeIfPresent(String.self, forKey: .userName)
        productsUsed = try values.decodeIfPresent(ProductsUsed.self, forKey: .productsUsed)
        settings = try values.decodeIfPresent(NabuUserSettings.self, forKey: .settings)
        personalDetails = try PersonalDetails(from: decoder)
        email = try Email(from: decoder)
        mobile = try? Mobile(from: decoder)
        status = (try? values.decode(KYC.AccountStatus.self, forKey: .status)) ?? .none
        state = (try? values.decode(UserState.self, forKey: .state)) ?? .none
        tags = try values.decodeIfPresent(Tags.self, forKey: .tags)
        needsDocumentResubmission = try values.decodeIfPresent(DocumentResubmission.self, forKey: .needsDocumentResubmission)
        kycCreationDate = try values.decodeIfPresent(String.self, forKey: .kycCreationDate)
        kycUpdateDate = try values.decodeIfPresent(String.self, forKey: .kycUpdateDate)

        depositAddresses = (try values.decodeIfPresent([String: String].self, forKey: .depositAddresses))
            .flatMap { data -> [DepositAddress] in
                data.compactMap { key, value -> DepositAddress? in
                    DepositAddress(stringType: key, address: value)
                }
            } ?? []
    }
}

extension NabuUser: User {}

extension NabuUser {
    /// User has a linked Exchange Account.
    ///
    /// If `ProductsUsed` property is present, use its `exchange` value.
    /// Else use value of `NabuUserSettings`s `mercuryEmailVerified`.
    /// Both `ProductsUsed` and `NabuUserSettings` are optionally present.
    public var hasLinkedExchangeAccount: Bool {
        if let productsUsed = productsUsed {
            return productsUsed.exchange
        } else if let mercuryEmailVerified = settings?.mercuryEmailVerified {
            return mercuryEmailVerified
        }
        return false
    }
}

extension NabuUser {
    public var isGoldTierVerified: Bool {
        guard let tiers = tiers else { return false }
        return tiers.current == .tier2
    }
}

extension NabuUser: NabuUserSunriverAirdropRegistering {
    public var isSunriverAirdropRegistered: Bool {
        tags?.sunriver != nil
    }
}

extension NabuUser: NabuUserBlockstackAirdropRegistering {
    public var isBlockstackAirdropRegistered: Bool {
        tags?.blockstack != nil
    }
}

extension NabuUser: NabuUserSimpleBuyEnabled {
    public var isSimpleBuyEnabled: Bool {
        tags?.simpleBuy != nil
    }
}

public struct Mobile: Decodable, Equatable {
    public let phone: String
    public let verified: Bool

    private enum CodingKeys: String, CodingKey {
        case phone = "mobile"
        case verified = "mobileVerified"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        phone = try values.decode(String.self, forKey: .phone)
        verified = try values.decodeIfPresent(Bool.self, forKey: .verified) ?? false
    }

    public init(phone: String, verified: Bool) {
        self.phone = phone
        self.verified = verified
    }
}

public struct Tags: Decodable, Equatable {

    private enum CodingKeys: String, CodingKey {
        case sunriver = "SUNRIVER"
        case blockstack = "BLOCKSTACK"
        case powerPax = "POWER_PAX"
        case simpleBuy = "SIMPLE_BUY"
    }

    public let sunriver: Sunriver?
    public let blockstack: Blockstack?
    public let powerPax: PowerPax?
    public let simpleBuy: SimpleBuy?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sunriver = try values.decodeIfPresent(Sunriver.self, forKey: .sunriver)
        blockstack = try values.decodeIfPresent(Blockstack.self, forKey: .blockstack)
        powerPax = try values.decodeIfPresent(PowerPax.self, forKey: .powerPax)
        simpleBuy = try values.decodeIfPresent(SimpleBuy.self, forKey: .simpleBuy)
    }

    public init(
        sunriver: Sunriver? = nil,
        blockstack: Blockstack? = nil,
        powerPax: PowerPax? = nil,
        simpleBuy: SimpleBuy? = nil
    ) {
        self.sunriver = sunriver
        self.blockstack = blockstack
        self.powerPax = powerPax
        self.simpleBuy = simpleBuy
    }

    public struct Sunriver: Decodable, Equatable {
        let campaignAddress: String

        private enum CodingKeys: String, CodingKey {
            case campaignAddress = "x-campaign-address"
        }
    }

    public struct SimpleBuy: Decodable, Equatable {}

    public struct Blockstack: Decodable, Equatable {
        let campaignAddress: String

        private enum CodingKeys: String, CodingKey {
            case campaignAddress = "x-campaign-address"
        }
    }

    public struct PowerPax: Decodable, Equatable {
        let campaignAddress: String

        private enum CodingKeys: String, CodingKey {
            case campaignAddress = "x-campaign-address"
        }
    }

    public var containsSimpleBuy: Bool {
        simpleBuy != nil
    }
}

public struct DocumentResubmission: Decodable, Equatable {
    public let reason: Int

    private enum CodingKeys: String, CodingKey {
        case reason
    }
}

public struct DepositAddress: Equatable {
    public let type: CryptoCurrency
    public let address: String

    public init?(
        stringType: String,
        address: String,
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()
    ) {
        guard let type = enabledCurrenciesService.allEnabledCryptoCurrencies
            .first(where: { $0.code == stringType.uppercased() })
        else {
            return nil
        }
        self.init(type: type, address: address)
    }

    public init(type: CryptoCurrency, address: String) {
        self.type = type
        self.address = address
    }
}

public struct NabuUserSettings: Decodable, Equatable {
    public let mercuryEmailVerified: Bool?

    private enum CodingKeys: String, CodingKey {
        case mercuryEmailVerified = "MERCURY_EMAIL_VERIFIED"
    }

    public init(mercuryEmailVerified: Bool) {
        self.mercuryEmailVerified = mercuryEmailVerified
    }
}
