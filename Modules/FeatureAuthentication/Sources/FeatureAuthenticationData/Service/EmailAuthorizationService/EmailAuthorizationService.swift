// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import Foundation
import ToolKit

public final class EmailAuthorizationService: EmailAuthorizationServiceAPI {

    private let lock = NSRecursiveLock()
    private var _isActive = false
    private var isActive: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isActive
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _isActive = newValue
        }
    }

    // MARK: - Injected

    private let guidService: GuidServiceAPI

    // MARK: - Setup

    public init(guidService: GuidServiceAPI) {
        self.guidService = guidService
    }

    /// Cancels the authorization by sending interrupt to stop polling
    public func cancel() {
        isActive = false
    }

    // MARK: - Accessors

    public func authorizeEmailPublisher() -> AnyPublisher<Void, EmailAuthorizationServiceError> {
        guidService
            .guid
            .mapToVoid()
            .catch { error -> AnyPublisher<Void, EmailAuthorizationServiceError> in
                switch error {
                case .missingGuid:
                    return .failure(.missingGuid)
                case .missingSessionToken:
                    return .failure(.missingSessionToken)
                case .networkError(let networkError):
                    return .failure(.guidService(.networkError(networkError)))
                }
            }
            .eraseToAnyPublisher()
    }
}
