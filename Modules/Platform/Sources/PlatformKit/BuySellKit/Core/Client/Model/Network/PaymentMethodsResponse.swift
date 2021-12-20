// Copyright © Blockchain Luxembourg S.A. All rights reserved.

/// The available payment methods
public struct PaymentMethodsResponse: Decodable {

    public struct Method: Decodable {

        /// The limits for a given window of time (e.g. annual or daily)
        struct Limits: Decodable {
            let available: String
            let limit: String
            let used: String

            enum CodingKeys: String, CodingKey {
                case available
                case limit
                case used
            }

            // MARK: - Init

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let availableValue = try values.decode(Int.self, forKey: .available)
                let limitValue = try values.decode(Int.self, forKey: .limit)
                let usedValue = try values.decode(Int.self, forKey: .used)
                available = String(availableValue)
                limit = String(limitValue)
                used = String(usedValue)
            }
        }

        struct PaymentMethodLimits: Decodable {
            /// The minimum limit per transaction
            let min: String
            /// The max limit per transaction
            let max: String
            /// The limits for the year
            let annual: Limits?
            /// The limits for a single day of transactions.
            let daily: Limits?
            /// The limits for a single week of transactions.
            let weekly: Limits?

            enum CodingKeys: String, CodingKey {
                case min
                case max
                case annual
                case daily
                case weekly
            }

            // MARK: - Init

            init(
                min: String,
                max: String,
                annual: Limits? = nil,
                daily: Limits? = nil,
                weekly: Limits? = nil
            ) {
                self.min = min
                self.max = max
                self.annual = annual
                self.daily = daily
                self.weekly = weekly
            }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                min = try values.decode(String.self, forKey: .min)
                max = try values.decode(String.self, forKey: .max)
                annual = try values.decodeIfPresent(Limits.self, forKey: .annual)
                daily = try values.decodeIfPresent(Limits.self, forKey: .daily)
                weekly = try values.decodeIfPresent(Limits.self, forKey: .weekly)
            }
        }

        let type: String

        /// The boundaries of the method (min / max)
        let limits: PaymentMethodLimits

        /// The supported subtypes of the payment method
        /// e.g for a card payment method: ["VISA", "MASTERCARD"]
        let subTypes: [String]

        /// The currency limiter of the method
        let currency: String?

        /// The eligible state of the payment
        let eligible: Bool

        /// When `true`, the payment method can be shown to the user
        let visible: Bool
    }

    /// The currency for the payment method (e.g: `USD`)
    let currency: String

    /// The available methods of payment
    let methods: [Method]
}

public struct PaymentCardAcquirer: Decodable {
    let cardAcquirerName: CardPayload.Acquirer
    /// List of the accounts (stripe_uk, stripe_us)
    let cardAcquirerAccountCodes: [String]
    let apiKey: String

    public init(
        cardAcquirerName: CardPayload.Acquirer,
        cardAcquirerAccountCodes: [String],
        apiKey: String
    ) {
        self.cardAcquirerName = cardAcquirerName
        self.cardAcquirerAccountCodes = cardAcquirerAccountCodes
        self.apiKey = apiKey
    }
}
