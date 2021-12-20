// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

public protocol PayloadRepositoryAPI: AnyObject {
    func set(payload: String) -> AnyPublisher<Void, Never>
}
