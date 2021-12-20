// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureTransactionDomain
import MoneyKit
import NabuNetworkError
import PlatformKit

final class BankTransferRepository: BankTransferRepositoryAPI {

    // MARK: - Properties

    private let client: BankTransferClientAPI

    // MARK: - Setup

    init(client: BankTransferClientAPI = resolve()) {
        self.client = client
    }

    // MARK: - BankTransferRepositoryAPI

    func startBankTransfer(
        id: String,
        amount: MoneyValue
    ) -> AnyPublisher<BankTranferPayment, NabuNetworkError> {
        client.startBankTransfer(id: id, amount: amount)
            .map(BankTranferPayment.init)
            .eraseToAnyPublisher()
    }
}
