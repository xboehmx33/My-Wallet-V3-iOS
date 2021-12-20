// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation

public protocol WalletConnectPublicKeyProviderAPI {
    var publicKey: AnyPublisher<String, Error> { get }
}
