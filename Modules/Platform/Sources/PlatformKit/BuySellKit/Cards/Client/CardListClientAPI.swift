// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import NabuNetworkError

public protocol CardListClientAPI: AnyObject {

    /// if enableProviders, will return cards tokenized with Stripe and Checkout.com
    func getCardList(enableProviders: Bool) -> AnyPublisher<[CardPayload], NabuNetworkError>
}
