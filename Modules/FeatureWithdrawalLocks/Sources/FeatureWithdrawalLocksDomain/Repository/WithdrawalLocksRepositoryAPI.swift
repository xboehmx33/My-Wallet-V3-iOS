// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation

public protocol WithdrawalLocksRepositoryAPI {
    func withdrawLocks(
        currencyCode: String
    ) -> AnyPublisher<WithdrawalLocks, Never>
}
