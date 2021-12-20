// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

public protocol BankTransferRepositoryAPI {

    func startBankTransfer(
        id: String,
        amount: MoneyValue
    ) -> AnyPublisher<BankTranferPayment, NabuNetworkError>
}
