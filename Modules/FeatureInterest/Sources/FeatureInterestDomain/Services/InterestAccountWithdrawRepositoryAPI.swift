// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError
import PlatformKit

public enum InterestAccountWithdrawRepositoryError: Error {
    case networkError(Error)
}

public protocol InterestAccountWithdrawRepositoryAPI: AnyObject {

    func createInterestAccountWithdrawal(
        _ amount: MoneyValue,
        address: String,
        currencyCode: String
    ) -> AnyPublisher<Void, InterestAccountWithdrawRepositoryError>
}
