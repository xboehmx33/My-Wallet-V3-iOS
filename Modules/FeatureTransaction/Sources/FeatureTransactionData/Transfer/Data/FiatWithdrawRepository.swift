// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureTransactionDomain
import MoneyKit
import NabuNetworkError
import PlatformKit

final class FiatWithdrawRepository: FiatWithdrawRepositoryAPI {

    // MARK: - Properties

    private let client: BankTransferClientAPI

    // MARK: - Setup

    init(client: BankTransferClientAPI = resolve()) {
        self.client = client
    }

    // MARK: - BankTransferServiceAPI

    func createWithdrawOrder(
        id: String,
        amount: MoneyValue
    ) -> AnyPublisher<Void, NabuNetworkError> {
        client.createWithdrawOrder(id: id, amount: amount)
    }
}
