// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureInterestDomain
import MoneyKit
import NabuNetworkError
import PlatformKit
import ToolKit

final class InterestAccountWithdrawRepository: InterestAccountWithdrawRepositoryAPI {

    // MARK: - Private Properties

    private let client: InterestAccountWithdrawClientAPI

    // MARK: - Init

    init(
        client: InterestAccountWithdrawClientAPI = resolve()
    ) {
        self.client = client
    }

    // MARK: - InterestAccountWithdrawRepositoryAPI

    func createInterestAccountWithdrawal(
        _ amount: MoneyValue,
        address: String,
        currencyCode: String
    ) -> AnyPublisher<Void, InterestAccountWithdrawRepositoryError> {
        client
            .createInterestAccountWithdrawal(
                amount,
                address: address,
                currencyCode: currencyCode
            )
            .mapToVoid()
            .mapError(InterestAccountWithdrawRepositoryError.networkError)
            .eraseToAnyPublisher()
    }
}
