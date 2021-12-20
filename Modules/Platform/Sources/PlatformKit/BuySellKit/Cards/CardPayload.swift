// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public struct CardPayload {

    public enum Partner: String {
        case everypay = "EVERYPAY"
        case cardProvider = "CARDPROVIDER"
        case unknown

        var isKnown: Bool {
            self != .unknown
        }
    }

    /// The id of the card
    let identifier: String

    /// The partner of the card
    let partner: CardPayload.Partner

    /// The billing address
    let address: BillingAddress!

    /// The currency of the card
    let currency: String

    /// The state (e.g: PENDING)
    let state: State

    /// The details on the card
    let card: CardDetails!

    /// The addition date (e.g: `2020-04-07T23:23:26.761Z`)
    let additionDate: String

    public init(
        identifier: String,
        partner: String,
        address: BillingAddress!,
        currency: String,
        state: State,
        card: CardDetails!,
        additionDate: String
    ) {
        self.identifier = identifier
        self.partner = Partner(rawValue: partner) ?? .unknown
        self.address = address
        self.currency = currency
        self.state = state
        self.card = card
        self.additionDate = additionDate
    }
}

// MARK: - Decodable

extension CardPayload: Decodable {

    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case partner
        case address
        case currency
        case state
        case card
        case additionDate = "addedAt"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try values.decode(String.self, forKey: .identifier)

        let partnerString = try values.decode(String.self, forKey: .partner)
        partner = Partner(rawValue: partnerString) ?? .unknown

        address = try values.decodeIfPresent(BillingAddress.self, forKey: .address)
        currency = try values.decode(String.self, forKey: .currency)

        state = try values.decodeIfPresent(State.self, forKey: .state) ?? .none

        additionDate = try values.decode(String.self, forKey: .additionDate)

        card = try values.decodeIfPresent(CardDetails.self, forKey: .card)
    }
}

// MARK: - Types

extension CardPayload {

    /// The card details
    public struct CardDetails {

        /// e.g `1234` (4 digits)
        let number: String

        /// e.g `10`
        let month: String?

        /// e.g `2021`
        let year: String?

        /// e.g: `MASTERCARD`
        let type: String

        /// e.g: `AS LHV BANK`
        let label: String
    }

    /// The partner for the card
    public enum Acquirer: String, Codable {

        /// EveryPay partner
        case everyPay = "EVERYPAY"

        /// Stripe partner
        case stripe = "STRIPE"

        /// Checkout.com partner
        case checkout = "CHECKOUTDOTCOM"

        /// Any other
        case unknown

        var isKnown: Bool {
            switch self {
            case .unknown:
                return false
            default:
                return true
            }
        }

        public init(acquirer: String) {
            self = Acquirer(rawValue: acquirer) ?? .unknown
        }
    }

    /// The state for a card
    public enum State: String, Decodable {

        // Initial card state
        case none = "NONE"

        // Waiting for activation
        case pending = "PENDING"

        // Card ready to be used
        case active = "ACTIVE"

        // Card created
        case created = "CREATED"

        // Blocked for fraud or other reason
        case blocked = "BLOCKED"

        /// Card under manual review
        case manualReview = "MANUAL_REVIEW"

        /// The card is under fraud review
        case fraudReview = "FRAUD_REVIEW"

        // Card is expired
        case expired = "EXPIRED"

        /// Card is active
        var isActive: Bool {
            switch self {
            case .active:
                return true
            default:
                return false
            }
        }

        /// This is `true` if the card is usable (created on BE, and was or is in a
        /// usable state.
        var isUsable: Bool {
            switch self {
            case .active, .blocked, .expired, .fraudReview, .manualReview:
                return true
            case .created, .none, .pending:
                return false
            }
        }
    }

    /// The billing address for a card
    public struct BillingAddress: Codable {
        public let line1: String
        public let line2: String?
        public let postCode: String
        public let city: String
        public let state: String?
        public let country: String
    }
}

extension CardPayload.CardDetails: Decodable {

    private enum CodingKeys: String, CodingKey {
        case number
        case expireMonth
        case expireYear
        case type
        case label
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        number = try values.decode(String.self, forKey: .number)

        if let month = try values.decodeIfPresent(Int.self, forKey: .expireMonth) {
            self.month = String(format: "%02d", month)
        } else {
            month = nil
        }

        if let year = try values.decodeIfPresent(Int.self, forKey: .expireYear) {
            self.year = "\(year)"
        } else {
            year = nil
        }

        type = try values.decode(String.self, forKey: .type)
        label = try values.decodeIfPresent(String.self, forKey: .label) ?? ""
    }
}
