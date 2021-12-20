// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

public enum PasswordRepositoryError: Error {
    case unavailable
    case syncFailed
}

public protocol PasswordRepositoryAPI: AnyObject {

    /// Streams `Bool` indicating whether a password is currently cached in the repo
    var hasPassword: AnyPublisher<Bool, Never> { get }

    /// Streams the cached password or `nil` if it is not cached
    var password: AnyPublisher<String?, Never> { get }

    /// Sets the password
    func set(password: String) -> AnyPublisher<Void, Never>

    /// Syncs the current `password` with the users wallet.
    /// This changes the users password.
    func sync() -> AnyPublisher<Void, PasswordRepositoryError>
}
