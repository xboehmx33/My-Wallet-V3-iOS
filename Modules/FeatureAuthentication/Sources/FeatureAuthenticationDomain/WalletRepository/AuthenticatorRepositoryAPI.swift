// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import WalletPayloadKit

public protocol AuthenticatorRepositoryAPI: AnyObject {

    /// Streams the authenticator type
    var authenticatorType: AnyPublisher<WalletAuthenticatorType, Never> { get }

    /// Sets the authenticator type
    func set(authenticatorType: WalletAuthenticatorType) -> AnyPublisher<Void, Never>
}
