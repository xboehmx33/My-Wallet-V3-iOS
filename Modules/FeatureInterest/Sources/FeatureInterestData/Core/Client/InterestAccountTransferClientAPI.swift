// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError
import PlatformKit

protocol InterestAccountTransferClientAPI {
    func createInterestAccountCustodialTransfer(
        _ amount: MoneyValue
    ) -> AnyPublisher<Void, NabuNetworkError>

    func createInterestAccountCustodialWithdraw(
        _ amount: MoneyValue
    ) -> AnyPublisher<Void, NabuNetworkError>
}
