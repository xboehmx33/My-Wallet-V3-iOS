// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import WalletPayloadKit

public enum WalletInfoError: Error {
    case failToDecodeBase64Component
    case failToDecodeToWalletInfo(Error)
    case sessionTokenMismatch(originSession: String, base64Str: String)
    case missingSessionToken(originSession: String, base64Str: String)
}

public struct WalletInfo: Codable, Equatable {

    // MARK: - Type

    private enum CodingKeys: String, CodingKey {
        case wallet
        case guid
        case email
        case sessionId = "session_id"
        case emailCode = "email_code"
        case twoFAType = "two_fa_type"
        case isMobileSetup = "is_mobile_setup"
        case hasCloudBackup = "has_cloud_backup"
        case nabu
        case unified
        case upgradeable
        case mergeable
        case userType = "user_type"
    }

    public enum UserType: String, Codable {
        /// only wallet
        case wallet = "WALLET"

        /// only exchange
        case exchange = "EXCHANGE"

        /// wallet object has embedded exchange object
        case linked = "WALLET_EXCHANGE_LINKED"

        /// payload has only root-level wallet & exchange objects
        case notLinked = "WALLET_EXCHANGE_NOT_LINKED"

        /// there are root-level wallet & exchange objects, but wallet also has embedded exchange object (e.g. tied to different e-mail & linked via legacy linking)
        case both = "WALLET_EXCHANGE_BOTH"
    }

    public struct NabuInfo: Codable, Equatable {
        public let userId: String
        public let recoveryToken: String

        private enum NabuInfoCodingKeys: String, CodingKey {
            case userId = "user_id"
            case recoveryToken = "recovery_token"
        }

        public init(
            userId: String,
            recoveryToken: String
        ) {
            self.userId = userId
            self.recoveryToken = recoveryToken
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: NabuInfoCodingKeys.self)
            userId = try container.decode(String.self, forKey: .userId)
            recoveryToken = try container.decode(String.self, forKey: .recoveryToken)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: NabuInfoCodingKeys.self)
            try container.encode(userId, forKey: .userId)
            try container.encode(recoveryToken, forKey: .recoveryToken)
        }
    }

    // MARK: - Properties

    public static let empty = WalletInfo(
        guid: "",
        email: nil,
        emailCode: nil,
        sessionId: nil,
        twoFAType: nil,
        isMobileSetup: nil,
        hasCloudBackup: nil,
        nabuInfo: nil,
        unified: nil,
        upgradeable: nil,
        mergeable: nil,
        userType: nil
    )

    public let guid: String
    public let email: String?
    public let emailCode: String?
    public let sessionId: String?
    public let twoFAType: WalletAuthenticatorType?
    public let isMobileSetup: Bool?
    public let hasCloudBackup: Bool?
    public let nabuInfo: NabuInfo?
    public let unified: Bool?
    public let upgradeable: Bool?
    public let mergeable: Bool?
    public let userType: UserType?

    // MARK: - Setup

    public init(
        guid: String,
        email: String? = nil,
        emailCode: String? = nil,
        sessionId: String? = nil,
        twoFAType: WalletAuthenticatorType? = nil,
        isMobileSetup: Bool? = nil,
        hasCloudBackup: Bool? = nil,
        nabuInfo: NabuInfo? = nil,
        unified: Bool? = nil,
        upgradeable: Bool? = nil,
        mergeable: Bool? = nil,
        userType: UserType? = nil
    ) {
        self.guid = guid
        self.email = email
        self.emailCode = emailCode
        self.sessionId = sessionId
        self.twoFAType = twoFAType
        self.isMobileSetup = isMobileSetup
        self.hasCloudBackup = hasCloudBackup
        self.nabuInfo = nabuInfo
        self.unified = unified
        self.upgradeable = upgradeable
        self.mergeable = mergeable
        self.userType = userType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder
            .container(keyedBy: CodingKeys.self)
        let wallet = try container
            .nestedContainer(keyedBy: CodingKeys.self, forKey: .wallet)
        guid = try wallet.decode(String.self, forKey: .guid)
        email = try wallet.decode(String.self, forKey: .email)
        emailCode = try wallet.decode(String.self, forKey: .emailCode)
        sessionId = try wallet.decodeIfPresent(String.self, forKey: .sessionId)
        twoFAType = try wallet.decode(WalletAuthenticatorType.self, forKey: .twoFAType)
        isMobileSetup = try wallet
            .decodeIfPresent(Bool.self, forKey: .isMobileSetup)
        hasCloudBackup = try wallet
            .decodeIfPresent(Bool.self, forKey: .hasCloudBackup)
        nabuInfo = try wallet
            .decodeIfPresent(NabuInfo.self, forKey: .nabu)
        unified = try container.decodeIfPresent(Bool.self, forKey: .unified)
        upgradeable = try container.decodeIfPresent(Bool.self, forKey: .upgradeable)
        mergeable = try container.decodeIfPresent(Bool.self, forKey: .mergeable)
        userType = try container.decodeIfPresent(UserType.self, forKey: .userType)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var wallet = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .wallet)
        try wallet.encode(guid, forKey: .guid)
        try wallet.encode(email, forKey: .email)
        try wallet.encode(emailCode, forKey: .emailCode)
        try wallet.encode(twoFAType, forKey: .twoFAType)
        try wallet.encodeIfPresent(sessionId, forKey: .sessionId)
        try wallet.encodeIfPresent(isMobileSetup, forKey: .isMobileSetup)
        try wallet.encodeIfPresent(hasCloudBackup, forKey: .hasCloudBackup)
        try wallet.encodeIfPresent(nabuInfo, forKey: .nabu)
        try wallet.encodeIfPresent(unified, forKey: .unified)
        try wallet.encodeIfPresent(upgradeable, forKey: .upgradeable)
        try wallet.encodeIfPresent(mergeable, forKey: .mergeable)
        try wallet.encodeIfPresent(userType, forKey: .userType)
    }
}

extension WalletInfo {

    /// Determine whether the account attached could be upgraded
    public var shouldUpgradeAccount: Bool {
        guard let unified = unified,
              let upgradeable = upgradeable,
              let mergeable = mergeable,
              self.userType != nil
        else {
            return false
        }
        return !unified && (upgradeable || mergeable)
    }
}
