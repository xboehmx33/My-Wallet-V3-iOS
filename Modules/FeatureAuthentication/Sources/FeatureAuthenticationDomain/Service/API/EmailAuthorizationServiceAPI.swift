// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

public enum EmailAuthorizationServiceError: Error {
    /// Session token is missing
    case missingSessionToken

    /// Guid is missing
    case missingGuid

    /// Instance of self was deallocated
    case unretainedSelf

    /// Authorization is already active
    case authorizationAlreadyActive

    /// Cancellation error
    case authorizationCancelled

    /// Guid Service Error
    case guidService(GuidServiceError)
}

public protocol EmailAuthorizationServiceAPI {

    func cancel()

    /// Checks whether the email authorization has been approved by checking the existence of GUID set at the backend
    /// - Returns: A Combine `Publisher`that returns Void on success (GUID exist) or
    ///  EmailAuthorizationServiceError on failure (including GUID not exist case)
    func authorizeEmailPublisher() -> AnyPublisher<Void, EmailAuthorizationServiceError>
}
