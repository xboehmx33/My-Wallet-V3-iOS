// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit
import ToolKit

struct AirdropCampaigns {

    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }

    struct Campaign {

        enum Name: String {
            case blockstack = "BLOCKSTACK"
            case sunriver = "SUNRIVER"
        }

        /// The computed state of the airdrop - it's much more simplified to look at
        enum CurrentState {

            /// The airdrop has expired
            case expired

            /// the user is not eligible
            case ineligible

            /// The airdrop has been received
            case received

            /// The airdrop has been claimed
            case claimed

            /// The user has been enrolled to the airdrop
            case enrolled

            /// Not registered
            case notRegistered
        }

        enum GeneralState: String, Decodable {
            case none = "NONE"
            case started = "STARTED"
            case ended = "ENDED"
        }

        enum UserState: String, Decodable {
            case none = "NONE"

            /// Enrolled
            case registered = "REGISTERED"

            /// Claimed (blockstack)
            case taskFinished = "TASK_FINISHED"

            /// Claimed (sunriver)
            case rewardSend = "REWARD_SEND"

            /// Received (sunriver)
            case rewardReceived = "REWARD_RECEIVED"

            /// Failed (declined)
            case failed = "FAILED"
        }

        struct Attributes {
            let address: String
            let code: String
            let email: String
            let rejectionReason: String
        }

        struct Transaction: Decodable {

            enum CodingKeys: String, CodingKey {
                case state = "userCampaignTransactionState"
                case fiatValue
                case fiatCurrency
                case withdrawalQuantity
                case withdrawalCurrency
                case withdrawalAt
            }

            enum State: String, Decodable {
                case none = "NONE"
                case pendingDeposit = "PENDING_DEPOSIT"
                case finishedDeposit = "FINISHED_DEPOSIT"
                case pendingWithdrawal = "PENDING_WITHDRAWAL"
                case finishedWithdrawal = "FINISHED_WITHDRAWAL"
                case failed = "FAILED"
            }

            let state: State
            let fiatValue: Decimal
            let fiatCurrency: String
            let withdrawalQuantity: Decimal
            let withdrawalCurrency: String
            let withdrawalAt: String

            var fiat: FiatValue {
                FiatValue.create(major: fiatValue / 100, currency: FiatCurrency(code: fiatCurrency)!)
            }

            var withdrawalDate: Date! {
                AirdropCampaigns.dateFormatter.date(from: withdrawalAt)
            }

            var cryptoCurrency: TriageCryptoCurrency! {
                try? TriageCryptoCurrency(code: withdrawalCurrency)
            }

            var isValid: Bool {
                cryptoCurrency != nil && withdrawalDate != nil
            }

            var crypto: CryptoValue? {
                guard let cryptoCurrency = cryptoCurrency.cryptoCurrency else {
                    return nil
                }
                return CryptoValue.create(minor: withdrawalQuantity, currency: cryptoCurrency)
            }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                state = try values.decode(State.self, forKey: .state)
                fiatValue = try values.decode(Decimal.self, forKey: .fiatValue)
                fiatCurrency = try values.decode(String.self, forKey: .fiatCurrency)
                withdrawalQuantity = try values.decode(Decimal.self, forKey: .withdrawalQuantity)
                withdrawalCurrency = try values.decode(String.self, forKey: .withdrawalCurrency)
                withdrawalAt = try values.decode(String.self, forKey: .withdrawalAt)
            }

            init(
                state: State,
                fiatValue: Decimal,
                fiatCurrency: String,
                withdrawalQuantity: Decimal,
                withdrawalCurrency: String,
                withdrawalAt: String
            ) {
                self.state = state
                self.fiatValue = fiatValue
                self.fiatCurrency = fiatCurrency
                self.withdrawalQuantity = withdrawalQuantity
                self.withdrawalCurrency = withdrawalCurrency
                self.withdrawalAt = withdrawalAt
            }
        }

        /// Validates the campaign's values
        var isValid: Bool {
            guard !name.isEmpty else { return false }
            guard state != .none else { return false }
            guard cryptoCurrency != nil else { return false }
            guard !(transactions.contains { !$0.isValid }) else { return false }
            return true
        }

        /// Returns the latest transaction
        var latestTransaction: Transaction? {
            transactions.first
        }

        /// Returns the crypto currency
        var cryptoCurrency: TriageCryptoCurrency! {
            if let cryptoCurrency = latestTransaction?.cryptoCurrency {
                return cryptoCurrency
            }
            guard let name = Name(rawValue: name) else {
                return nil
            }
            switch name {
            case .blockstack:
                return .blockstack
            case .sunriver:
                return TriageCryptoCurrency(cryptoCurrency: .coin(.stellar))
            }
        }

        var cryptoDisplayValue: String? {
            guard let latestTransaction = latestTransaction else { return nil }
            if let cryptoDisplayValue = latestTransaction.crypto?.toDisplayString(includeSymbol: false) {
                return cryptoDisplayValue
            }
            guard let name = Name(rawValue: name) else {
                return nil
            }
            switch name {
            case .blockstack:
                guard let amount = BigInt("\(latestTransaction.withdrawalQuantity)") else { return nil }
                return latestTransaction.cryptoCurrency.displayValue(amount: amount)
            default:
                return nil
            }
        }

        /// Returns the state of the user in relation to the campaign state
        var currentState: CurrentState {
            /// If the campaign is supported continue
            guard let name = Name(rawValue: name) else {
                return .notRegistered
            }
            switch (name, state, userState) {
            case (_, _, .rewardReceived): // The reward has been received
                return .received
            case (.blockstack, .ended, .taskFinished): // STX ended and the user has claimed (pending to receive)
                return .claimed
            case (_, .ended, _): // The campagin had ended but the reward wasn't received
                return .expired
            case (_, .started, .failed): // User ineligible
                return .ineligible
            case (_, .started, .taskFinished), (_, .started, .rewardSend): // User has claimed the reward
                return .claimed
            case (_, .started, .registered): // User has enrolled
                return .enrolled
            case (_, .started, .none): // User hasn't registered yet
                return .notRegistered
            default:
                return .notRegistered
            }
        }

        /// The airdrop date
        var dropDate: Date? {

            /// If the end date is known it's simple - just return it.
            /// Typically, if a campaign ends, the date will be known
            if let endDate = endDate {
                return endDate
            }
            /// If the latest transaction exists and `withdrawalData` not nil
            /// just return it as this is the most reliable date of the transaction
            if let date = latestTransaction?.withdrawalDate {
                return date
            }

            /// If the campaign is supported continue
            guard let name = Name(rawValue: name) else {
                return nil
            }

            switch name {
            case .blockstack:
                switch userState {
                case .rewardReceived:
                    /// The airdrop has been claimed by the user, so `updateDate` should be
                    /// provided by the backend
                    return updateDate
                default:
                    /// NOTE: Blockstack campaign `dropDate`'s value is hardcoded because the backend
                    /// does not return that data in case the `userState` is NOT `rewardReceived`.
                    return Calendar.current.date(from: .init(year: 2020, month: 1, day: 7))
                }
            case .sunriver: // For XLM, return thr last update date
                return updateDate
            }
        }

        let name: String
        let state: GeneralState

        private let userState: UserState
        private let attributes: Attributes

        /// The tranactions are sorted chronologically in a descending order
        private let transactions: [Transaction]

        /// The date of the last status change on the backend side.
        private let endDate: Date?
        private let updateDate: Date?

        init(
            name: String,
            state: GeneralState,
            userState: UserState,
            attributes: Attributes,
            transactions: [Transaction],
            updateDate: Date?,
            endDate: Date?
        ) {
            self.name = name
            self.state = state
            self.userState = userState
            self.attributes = attributes
            self.transactions = transactions
            self.updateDate = updateDate
            self.endDate = endDate
        }
    }

    let campaigns: Set<Campaign>

    var ended: Set<Campaign> {
        campaigns.filter { $0.state == .ended }
    }

    var started: Set<Campaign> {
        campaigns.filter { $0.state == .started }
    }

    func campaign(by name: Campaign.Name) -> Campaign? {
        campaigns.first { $0.name == name.rawValue }
    }
}

// MARK: - Hashable

extension AirdropCampaigns.Campaign: Hashable {

    // MARK: - Equatable

    static func == (lhs: AirdropCampaigns.Campaign, rhs: AirdropCampaigns.Campaign) -> Bool {
        lhs.name == rhs.name
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

// MARK: - Decodable

extension AirdropCampaigns: Decodable {
    enum CodingKeys: String, CodingKey {
        case campaigns = "userCampaignsInfoResponseList"
    }

    // MARK: - Setup + Validation

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let campaigns = try values.decode([Campaign].self, forKey: .campaigns)
        self.campaigns = Set(campaigns.filter(\.isValid))
    }
}

extension AirdropCampaigns.Campaign: Decodable {
    enum CodingKeys: String, CodingKey {
        case name = "campaignName"
        case state = "campaignState"
        case userState = "userCampaignState"
        case endDate = "campaignEndDate"
        case updateDate = "updatedAt"
        case attributes
        case transactions = "userCampaignTransactionResponseList"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)

        if let updateDate = try values.decodeIfPresent(String.self, forKey: .updateDate) {
            self.updateDate = AirdropCampaigns.dateFormatter.date(from: updateDate)
        } else {
            updateDate = nil
        }

        if let endDate = try values.decodeIfPresent(String.self, forKey: .endDate) {
            self.endDate = AirdropCampaigns.dateFormatter.date(from: endDate)
        } else {
            endDate = nil
        }

        state = try values.decodeIfPresent(GeneralState.self, forKey: .state) ?? .none
        userState = try values.decodeIfPresent(UserState.self, forKey: .userState) ?? .none
        attributes = try values.decodeIfPresent(Attributes.self, forKey: .attributes) ?? .empty
        transactions = try values.decode([Transaction].self, forKey: .transactions).sorted(by: >)
    }
}

extension AirdropCampaigns.Campaign.Attributes: Decodable {
    enum CodingKeys: String, CodingKey {
        case address = "x-campaign-address"
        case code = "x-campaign-code"
        case email = "x-campaign-email"
        case rejectionReason = "x-campaign-reject-reason"
    }

    static var empty: AirdropCampaigns.Campaign.Attributes {
        .init(address: "", code: "", email: "", rejectionReason: "")
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        address = try values.decodeIfPresent(String.self, forKey: .address) ?? ""
        code = try values.decodeIfPresent(String.self, forKey: .code) ?? ""
        email = try values.decodeIfPresent(String.self, forKey: .email) ?? ""
        rejectionReason = try values.decodeIfPresent(String.self, forKey: .rejectionReason) ?? ""
    }
}

// MARK: - Comparable

extension AirdropCampaigns.Campaign.Transaction: Comparable {
    static func < (lhs: AirdropCampaigns.Campaign.Transaction, rhs: AirdropCampaigns.Campaign.Transaction) -> Bool {
        let lhsDate = lhs.withdrawalDate ?? .distantPast
        let rhsDate = rhs.withdrawalDate ?? .distantPast
        return lhsDate < rhsDate
    }
}
