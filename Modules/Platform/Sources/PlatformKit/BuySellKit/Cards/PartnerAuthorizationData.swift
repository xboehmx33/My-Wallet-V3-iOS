// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public struct PartnerAuthorizationData {

    public static var exitLink = "https://www.blockchain.com/"

    /// Required authorization type
    public enum State: Equatable {
        public struct PaymentParams: Equatable {
            public let cardAcquirer: CardPayload.Acquirer
            public let clientSecret: String?
            public let publishableApiKey: String?
            public let paymentLink: URL?
            public let exitLink: URL

            public init(
                cardAcquirer: CardPayload.Acquirer,
                clientSecret: String? = nil,
                paymentLink: URL? = nil,
                publishableApiKey: String? = nil
            ) {
                self.cardAcquirer = cardAcquirer
                self.paymentLink = paymentLink
                self.clientSecret = clientSecret
                self.publishableApiKey = publishableApiKey
                exitLink = URL(string: PartnerAuthorizationData.exitLink)!
            }
        }

        /// Requires user user authorization by visiting the associated link
        case required(PaymentParams)

        /// Confirmed authorization
        case confirmed

        /// Authorized to proceed - no auth required
        case none

        var isRequired: Bool {
            switch self {
            case .required:
                return true
            case .confirmed, .none:
                return false
            }
        }

        var isConfirmed: Bool {
            switch self {
            case .confirmed:
                return true
            case .required, .none:
                return false
            }
        }
    }

    /// The type of required authorization
    public let state: State

    /// The payment method id that needs to be authorized
    public let paymentMethodId: String
}

extension PartnerAuthorizationData {
    init?(orderPayloadResponse: OrderPayload.Response) {
        guard let paymentMethodId = orderPayloadResponse.paymentMethodId else {
            return nil
        }
        self.paymentMethodId = paymentMethodId
        state = orderPayloadResponse.authorizationState
    }
}
