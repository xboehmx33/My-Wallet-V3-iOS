// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ToolKit
import WalletPayloadKit

public struct WalletService {
    public var fetch: (_ password: String) -> AnyPublisher<EmptyValue, WalletError>
    public var refetch: (_ password: String, _ secondPassword: String) -> AnyPublisher<EmptyValue, WalletError>
}

extension WalletService {
    public static func live(fetcher: WalletFetcherAPI) -> WalletService {
        WalletService(
            fetch: { password -> AnyPublisher<EmptyValue, WalletError> in
                fetcher.fetch(using: password)
            },
            refetch: { _, _ -> AnyPublisher<EmptyValue, WalletError> in
                .empty()
            }
        )
    }
}
