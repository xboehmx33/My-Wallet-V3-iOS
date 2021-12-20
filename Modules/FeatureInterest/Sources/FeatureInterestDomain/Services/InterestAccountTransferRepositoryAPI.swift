// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError
import PlatformKit

public enum InterestAccountTransferRepositoryError: Error {
    case networkError(Error)
}

public protocol InterestAccountTransferRepositoryAPI {

    func createInterestAccountCustodialTransfer(
        _ amount: MoneyValue
    ) -> AnyPublisher<Void, InterestAccountWithdrawRepositoryError>

    func createInterestAccountCustodialWithdraw(
        _ amount: MoneyValue
    ) -> AnyPublisher<Void, InterestAccountWithdrawRepositoryError>
}
