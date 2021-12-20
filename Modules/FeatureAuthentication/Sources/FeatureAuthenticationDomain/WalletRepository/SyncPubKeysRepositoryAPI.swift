// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

public protocol SyncPubKeysRepositoryAPI: AnyObject {
    func set(syncPubKeys: Bool) -> AnyPublisher<Void, Never>
}
