// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import PlatformKit
import ToolKit

class NoOpKYCVerificationService: KYCVerificationServiceAPI {

    var isKYCVerified: AnyPublisher<Bool, Never> {
        .empty()
    }

    var canPurchaseCrypto: AnyPublisher<Bool, Never> {
        .empty()
    }
}
