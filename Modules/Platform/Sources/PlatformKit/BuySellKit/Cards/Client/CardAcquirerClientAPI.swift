// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import UIKit

struct CardTokenizationResponse {
    let token: String
    let accounts: [String]

    var params: [String: String] {
        accounts.reduce(into: [String: String]()) { params, code in
            params[code] = token
        }
    }
}

enum CardAcquirerError: Error {
    case emptyPublishableKey
    case missingParameters
    case unknownAcquirer
    case clientError(Error)
}

protocol CardAcquirerClientAPI {
    func tokenize(_ card: CardData, accounts: [String]) -> AnyPublisher<CardTokenizationResponse, CardAcquirerError>
    static func authorizationState(
        _ acquirer: ActivateCardResponse.CardAcquirer
    ) -> PartnerAuthorizationData.State
}
