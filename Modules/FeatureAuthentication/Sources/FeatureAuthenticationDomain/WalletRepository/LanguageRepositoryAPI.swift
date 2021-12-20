// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

public protocol LanguageRepositoryAPI: AnyObject {
    func set(language: String) -> AnyPublisher<Void, Never>
}
