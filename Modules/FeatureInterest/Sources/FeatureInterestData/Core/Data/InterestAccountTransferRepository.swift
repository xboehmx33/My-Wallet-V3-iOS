// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureInterestDomain
import MoneyKit
import NabuNetworkError
import PlatformKit
import ToolKit

final class InterestAccountTransferRepository: InterestAccountTransferRepositoryAPI {

    // MARK: - Private Properties

    private let client: InterestAccountTransferClientAPI

    // MARK: - Init

    init(
        client: InterestAccountTransferClientAPI = resolve()
    ) {
        self.client = client
    }

    // MARK: - InterestAccountTransferRepositoryAPI

    func createInterestAccountCustodialTransfer(
        _ amount: MoneyValue
    ) -> AnyPublisher<Void, InterestAccountWithdrawRepositoryError> {
        client
            .createInterestAccountCustodialTransfer(amount)
            .mapError(InterestAccountWithdrawRepositoryError.networkError)
            .eraseToAnyPublisher()
    }

    func createInterestAccountCustodialWithdraw(
        _ amount: MoneyValue
    ) -> AnyPublisher<Void, InterestAccountWithdrawRepositoryError> {
        client
            .createInterestAccountCustodialWithdraw(amount)
            .mapError(InterestAccountWithdrawRepositoryError.networkError)
            .eraseToAnyPublisher()
    }
}
