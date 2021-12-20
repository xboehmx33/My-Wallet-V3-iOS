// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureOpenBankingDomain
import Foundation
import MoneyKit

public struct FastlinkConfiguration {
    public let config: String?
}

public struct BankLinkageData {
    public enum Partner: String {
        case yodlee = "YODLEE"
        case yapily = "YAPILY"
    }

    public let token: String?
    public let fastlinkUrl: String?
    public let fastlinkParams: FastlinkConfiguration
    public let partner: Partner
    public let id: String
    public let entity: String?
    public let institutions: [OpenBanking.Institution]?
    public let currency: FiatCurrency

    init?(from response: CreateBankLinkageResponse, currency: FiatCurrency) {
        self.currency = currency
        guard let attributes = response.attributes else {
            return nil
        }
        token = attributes.token
        fastlinkUrl = attributes.fastlinkUrl
        fastlinkParams = FastlinkConfiguration(config: attributes.fastlinkParams?.configName)
        partner = Partner(from: response.partner)
        id = response.id
        entity = attributes.entity
        institutions = attributes.institutions
    }
}

extension BankLinkageData.Partner {
    init(from response: BankLinkagePartner) {
        switch response {
        case .yodlee:
            self = .yodlee
        case .yapily:
            self = .yapily
        }
    }

    public var title: String {
        switch self {
        case .yodlee:
            return "Yodlee"
        case .yapily:
            return "Yapily"
        }
    }
}

extension OpenBanking.BankAccount {

    public init(_ data: BankLinkageData) {
        self.init(
            id: .init(data.id),
            partner: data.partner.rawValue,
            attributes: .init(
                entity: data.entity ?? "Safeconnect(UK)",
                institutions: data.institutions
            )
        )
    }
}
